//
//  DFSClient.swift
//  DFSClient
//
//  Created by Adnan Joraid on 2024-12-14.
//

import Foundation
import GRPC
import NIO
import CryptoSwift

class DFSClient {
    private let address: String
    private let mountPath: String
    private let timeout: Int
    private var client: DFSServiceNIOClient?
    private var userID: String
    
    init(address: String, mountPath: String, timeout: Int) {
        self.address = address
        self.mountPath = mountPath
        self.timeout = timeout
        userID = UUID().uuidString
    }
    
    func processCommand(for command: DFSClientCLI.Command, fileName: String) {
        switch command {
        case .fetch:
            fetch(fileName)
        case .store:
            store(fileName)
        case .delete:
            delete(fileName)
        case .mount:
            return
        }
    }
    
    private func inotifyWatcher() {}
    private func setupInotifySharedMemory() {}
    
    func run() {
        let configuration = ClientConnection(configuration: .default(target: .hostAndPort(address, 27000),
                                                                     eventLoopGroup: MultiThreadedEventLoopGroup(numberOfThreads: 1)))
        client = DFSServiceNIOClient(channel: configuration)
    }
    
    private func lock(_ filename: String) -> GRPCStatus.Code {
        guard let client else {
            print("LOG: Tried calling lock but client is nil")
            return GRPCStatus.Code.cancelled
        }
        var request = FileRequest()
        request.fileName = filename
        request.userid = userID
        let status = client.lock(request)
        do {
            let _ = try status.response.wait()
            print("Response received")
            return GRPCStatus.Code.ok
        } catch let grpcError as GRPCStatus {
            print("Error while waiting for response: \(grpcError)")
            return grpcError.code
        } catch {
            print("Unexpected error: \(error)")
            return GRPCStatus.Code.unknown
        }
    }
    
    private func store(_ filename: String) {
        guard let client else {
            print("LOG: Tried calling store but client is nil")
            return
        }

        if lock(filename) == .resourceExhausted {
            print("File already locked on server: \(filename). Skipping upload.")
            return
        }

        var request = FileRequest()
        request.fileName = filename
        let chunkSize = 1024
        let fileURL = URL(fileURLWithPath: "./\(mountPath)/\(filename)")

        do {
            let call = client.store()
            let fileHandle = try FileHandle(forReadingFrom: fileURL)

            while let chunk = try? fileHandle.read(upToCount: chunkSize), !chunk.isEmpty {
                request.fileContent = chunk
                try call.sendMessage(request).wait()
            }

            try call.sendEnd().wait()

            call.response.whenComplete { result in
                switch result {
                case .success(let response):
                    print("Successfully stored file on server: \(response)")
                case .failure(let error):
                    if let grpcError = error as? GRPCStatus, grpcError.code == .alreadyExists {
                        print("Server rejected storage: File already exists.")
                    } else {
                        print("Failure: \(error)")
                    }
                }
            }

            try fileHandle.close()

        } catch {
            if let grpcError = error as? GRPCStatus, grpcError.code == .alreadyExists {
                print("Server rejected storage: File already exists.")
            } else {
                print("Error during file operation: \(error)")
            }
        }
    }

    private func fetch(_ filename: String) {
        guard let client = client else {
            print("LOG: Tried calling fetch but client is nil")
            return
        }
        let path = "./\(self.mountPath)/\(filename)"
        var request = FileRequest()
        request.fileName = filename
        request.fileChecksum = getFileCheckSum(filename)
        request.mtime = UInt64(getFileModificationTime(filePath: path)?.timeIntervalSince1970 ?? 0)
        print("mtime: \(request.mtime)")
        let call = client.fetch(request) { response in
            print("Received chunk: \(response.fileContent) bytes")
            
            let fileURL = URL(fileURLWithPath: path)
            
            if !FileManager.default.fileExists(atPath: path) {
                FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
            }
            
            do {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                defer { try? fileHandle.close() }
                fileHandle.seekToEndOfFile()
                fileHandle.write(response.fileContent)
            } catch {
                print("Error writing to file: \(error.localizedDescription)")
            }
        }
        do { _ = try call.status.wait() } catch { print(error) }
    }
    
    private func delete(_ filename: String) {
        guard let client = client else {
            print("LOG: Tried calling store but client is nil")
            return
        }
        if lock(filename) == .resourceExhausted {
            print("File already locked on server: \(filename). Skipping upload.")
            return
        }
        var data = FileRequest()
        data.fileName = filename
        let status = client.delete(data)
        do {
            let _ = try status.response.wait()
            print("Response received successfully.")
        } catch {
            print("Error while waiting for the response: \(error)")
        }
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
