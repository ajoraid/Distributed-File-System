//
//  DFSServiceNode.swift
//  DFSServer
//
//  Created by Adnan Joraid on 2024-12-16.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import GRPC
import NIOCore
import NIOPosix
import CryptoSwift
import RxSwift

class DFSServiceNode: DFSServiceProvider {
    let eventLoopGroup: EventLoopGroup
    let mountPath: String
    let deadline: Int64
    var tombstones = [Stones]()
    
    init(eventLoopGroup: EventLoopGroup, mountPath: String, deadline: Int64, interceptors: (any DFSServiceServerInterceptorFactoryProtocol)? = nil) {
        self.eventLoopGroup = eventLoopGroup
        self.mountPath = mountPath
        self.deadline = deadline
        self.interceptors = interceptors
    }
    
    var interceptors: (any DFSServiceServerInterceptorFactoryProtocol)?
    
    private func notifyFileSocketServer() {
        let baseURL = URL(string: "http://127.0.0.1:8080")!
        let notifyEndpoint = baseURL.appendingPathComponent("notify")
        var request = URLRequest(url: notifyEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
        }
        task.resume()
    }
    
    func pubSubFileEvents(request: EmptyResponse, context: any GRPC.StatusOnlyCallContext) -> NIOCore.EventLoopFuture<FilesList> {
        let promise = context.eventLoop.makePromise(of: FilesList.self)
        var response = FilesList()
        response.tombstones.append(contentsOf: tombstones)
        do {
            let filesList = try FileManager.default.contentsOfDirectory(atPath: "./\(mountPath)")
            let files = filesList.filter { item in
                var isDirectory: ObjCBool = false
                let fullPath = (mountPath as NSString).appendingPathComponent(item)
                FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory)
                return !isDirectory.boolValue
            }
            response.files.append(contentsOf: files.map { getFileStats($0) })
            promise.succeed(response)
        } catch {
            promise.fail(GRPCStatus(code: .internalError, message: "Error getting server files"))
        }
        return promise.futureResult
    }
    
    private func getFileStats(_ filename: String) -> FileRequest {
        return FileRequest.with {
            $0.fileName = filename
            $0.fileChecksum = getFileCheckSum(filename)
            $0.mtime = UInt64(getFileModificationTime(filePath: "./\(mountPath)/\(filename)")?.timeIntervalSince1970 ?? 0)
        }
    }
    
    func lock(request: FileRequest,
              context: GRPC.StatusOnlyCallContext) -> EventLoopFuture<EmptyResponse> {
        let promise = context.eventLoop.makePromise(of: EmptyResponse.self)
        Task {
            let res = await WriterLockMap.shared.insert(request.fileName,
                                                        request.userid,
                                                        deadline)
            if !res {
                return promise.fail(GRPCStatus(code: .resourceExhausted, message: "File already locked"))
            }
        }
        promise.succeed(EmptyResponse())
        return promise.futureResult
    }
    
    func store(context: GRPC.UnaryResponseCallContext<FileContent>) -> EventLoopFuture<(GRPC.StreamEvent<FileRequest>) -> Void> {
        var madeEmpty = false
        var filenametemp: String?
        let handler: (GRPC.StreamEvent<FileRequest>) -> Void = { [weak self] event in
            guard let self else { return }
            switch event {
            case .message(let fileRequest):
                if let toBeRemovedFromTombstone = tombstones.first(where: {$0.fileName == fileRequest.fileName}) {
                    if toBeRemovedFromTombstone.deletionTime > fileRequest.mtime {
                        Task { await WriterLockMap.shared.remove(fileRequest.fileName) }
                        return context.responsePromise.fail(
                            GRPCStatus(code: .aborted, message: "File was deleted recently")
                        )
                    }
                    tombstones.removeAll(where: {$0.fileName == fileRequest.fileName})
                }
                let path = "./\(self.mountPath)/\(fileRequest.fileName)"
                filenametemp = fileRequest.fileName
                do {
                    
                    if !FileManager.default.fileExists(atPath: path) {
                        FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
                    }
                    
                    let fileURL = URL(fileURLWithPath: path)
                    let fileHandle = try FileHandle(forWritingTo: fileURL)
                    if !madeEmpty { fileHandle.truncateFile(atOffset: 0); madeEmpty.toggle() }
                    defer { try? fileHandle.close() }
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(fileRequest.fileContent)
                    
                } catch {
                    print("Error writing file: \(error)")
                    Task { await WriterLockMap.shared.remove(fileRequest.fileName) }
                    return context.responsePromise.fail(
                        GRPCStatus(code: .internalError, message: "Error writing file: \(error.localizedDescription)")
                    )
                }
                
            case .end:
                print("Stream ended")
                if let filenametemp { Task { await WriterLockMap.shared.remove(filenametemp) } }
                context.responsePromise.succeed(FileContent())
            }
        }
        notifyFileSocketServer()
        return context.eventLoop.makeSucceededFuture(handler)
    }
    
    
    func fetch(request: FileRequest,
               context: GRPC.StreamingResponseCallContext<FileContent>) -> NIOCore.EventLoopFuture<GRPC.GRPCStatus> {
        let promise = context.eventLoop.makePromise(of: GRPCStatus.self)
        let path = "./\(self.mountPath)/\(request.fileName)"
        if !FileManager.default.fileExists(atPath: path) {
            promise.fail(GRPCStatus(code: .notFound, message: "File was not found on server"))
            return promise.futureResult
        }
        
        if request.mtime > UInt64(getFileModificationTime(filePath: path)?.timeIntervalSince1970 ?? 0) {
            promise.fail(GRPCStatus(code: .cancelled, message: "File is old"))
            return promise.futureResult
        }
        var content = FileContent()
        let chunkSize = 1024
        let fileURL = URL(fileURLWithPath: path)
        do {
            let fileHandle = try FileHandle(forReadingFrom: fileURL)
            while let chunk = try? fileHandle.read(upToCount: chunkSize), !chunk.isEmpty {
                content.fileContent = chunk
                let _ = context.sendResponse(content)
                
            }
            try fileHandle.close()
            promise.succeed(.ok)
        } catch {
            promise.fail(GRPCStatus(code: .internalError, message: "Failed to read file: \(error.localizedDescription)"))
            return promise.futureResult
        }
        return promise.futureResult
    }
    
    func delete(request: FileRequest,
                context: any GRPC.StatusOnlyCallContext) -> NIOCore.EventLoopFuture<EmptyResponse> {
        let path = "./\(self.mountPath)/\(request.fileName)"
        
        if !FileManager.default.fileExists(atPath: path) {
            return context.eventLoop.makeFailedFuture(GRPCStatus(code: .notFound))
        }
        do {
            tombstones.append(.with{
                $0.fileName = request.fileName
                $0.deletionTime = UInt64(Date().timeIntervalSince1970 * 1000)
            })
            try FileManager.default.removeItem(atPath: path)
            notifyFileSocketServer()
        } catch {
            return context.eventLoop.makeFailedFuture(GRPCStatus(code: .internalError))
        }
        let response = EmptyResponse()
        return context.eventLoop.makeSucceededFuture(response)
    }
    
    private func getFileCheckSum(_ filename: String) -> UInt32 {
        let path = "./\(mountPath)/\(filename)"
        let fileURL = URL(fileURLWithPath: path)
        
        if !FileManager.default.fileExists(atPath: path) {
            print("File does not exist. Checksum failed")
            return 0
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let checksum = Checksum.crc32(Array(data))
            print(checksum)
            return checksum
        } catch {
            print(error.localizedDescription)
        }
        return 0
    }
    
    func getFileModificationTime(filePath: String) -> Date? {
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfItem(atPath: filePath)
            if let modificationDate = attributes[.modificationDate] as? Date {
                return modificationDate
            }
        } catch {
            print("Error getting file attributes: \(error)")
        }
        return nil
    }
}
