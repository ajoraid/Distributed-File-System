//
//  DFSServiceNode.swift
//  DFSServer
//
//  Created by Adnan Joraid on 2024-12-16.
//

import Foundation
import GRPC
import NIOCore
import NIOPosix

class DFSServiceNode: DFSServiceProvider {
    let eventLoopGroup: EventLoopGroup
    let mountPath: String
    let deadline: Int64
    
    init(eventLoopGroup: EventLoopGroup, mountPath: String, deadline: Int64, interceptors: (any DFSServiceServerInterceptorFactoryProtocol)? = nil) {
        self.eventLoopGroup = eventLoopGroup
        self.mountPath = mountPath
        self.deadline = deadline
        self.interceptors = interceptors
    }
    
    var interceptors: (any DFSServiceServerInterceptorFactoryProtocol)?
    
    func lock(request: FileRequest,
              context: GRPC.StatusOnlyCallContext) -> EventLoopFuture<EmptyResponse> {
        let promise = context.eventLoop.makePromise(of: EmptyResponse.self)
        print("lock called with \(request.fileName) id: \(request.userid)")
        Task {
            let res = await WriterLockMap.shared.insert(request.fileName,
                                                        request.userid,
                                                        deadline)
            if !res {
                print("file already locked")
                promise.fail(GRPCStatus(code: .resourceExhausted, message: "File already locked"))
            }
            promise.succeed(EmptyResponse())
        }
        return promise.futureResult
    }
    
    func store(context: GRPC.UnaryResponseCallContext<FileContent>) -> EventLoopFuture<(GRPC.StreamEvent<FileRequest>) -> Void> {
        var checked = false
        var filenametemp: String?
        let handler: (GRPC.StreamEvent<FileRequest>) -> Void = { [weak self] event in
            guard let self else { return }
            switch event {
            case .message(let fileRequest):
                let path = "./\(self.mountPath)/\(fileRequest.fileName)"
                filenametemp = fileRequest.fileName
                do {
                    if !checked && FileManager.default.fileExists(atPath: path) {
                        print("File already exists: \(fileRequest.fileName)")
                        Task { await WriterLockMap.shared.remove(fileRequest.fileName) }
                        context.responsePromise.fail(
                            GRPCStatus(code: .alreadyExists, message: "File already exists at STORE request")
                        )
                        return
                    }

                    if !FileManager.default.fileExists(atPath: path) {
                        FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
                        checked = true
                    }

                    let fileURL = URL(fileURLWithPath: path)
                    let fileHandle = try FileHandle(forWritingTo: fileURL)
                    fileHandle.seekToEndOfFile()
                    try fileHandle.write(contentsOf: fileRequest.fileContent)

                } catch {
                    print("Error writing file: \(error)")
                    Task { await WriterLockMap.shared.remove(fileRequest.fileName) }
                    context.responsePromise.fail(
                        GRPCStatus(code: .internalError, message: "Error writing file: \(error.localizedDescription)")
                    )
                }

            case .end:
                print("Stream ended")
                if let filenametemp { Task { await WriterLockMap.shared.remove(filenametemp) } }
                context.responsePromise.succeed(FileContent())
            }
        }

        return context.eventLoop.makeSucceededFuture(handler)
    }

    
    func fetch(request: FileRequest,
               context: GRPC.StreamingResponseCallContext<FileContent>) -> NIOCore.EventLoopFuture<GRPC.GRPCStatus> {
        return GRPCStatus.ok as! EventLoopFuture<GRPCStatus>
    }
    
    func delete(request: FileRequest,
                context: any GRPC.StatusOnlyCallContext) -> NIOCore.EventLoopFuture<EmptyResponse> {
        print("delete got called with \(request.fileName)")
        let response = EmptyResponse()
        return context.eventLoop.makeSucceededFuture(response)
        
    }
}
