//
//  DFSClient.swift
//  DFSClient
//
//  Created by Adnan Joraid on 2024-12-14.
//

import Foundation
import GRPC
import NIO

class DFSClient {
    private let address: String
    private let mountPath: String
    private let timeout: Int
    private var client: DFSServiceNIOClient?
    
    init(address: String, mountPath: String, timeout: Int) {
        self.address = address
        self.mountPath = mountPath
        self.timeout = timeout
    }
    
    func processCommand(for command: DFSClientCLI.Command, fileName: String) {
        switch command {
        case .fetch:
            return
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
    
    private func store(_ filename: String) {
        guard let client else {
            print("LOG: Tried calling store but client is nil")
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
                let send = call.sendMessage(request)
                print(chunk)
                try send.wait()
            }
            _ = call.sendEnd()
            call.response.whenComplete { result in
                switch result {
                case .success(let success):
                    print("Recieved response: \(success)")
                case .failure(let failure):
                    print("Failure: \(failure)")
                }
            }
            try fileHandle.close()
        } catch {
            print("Error opening or reading from file: \(filename)")
        }
    }
    
    private func delete(_ filename: String) {
        guard let client = client else {
            print("LOG: Tried calling store but client is nil")
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
}
