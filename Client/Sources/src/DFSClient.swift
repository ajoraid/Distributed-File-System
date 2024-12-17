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
        store(fileName)
    }
    
    private func inotifyWatcher() {}
    private func setupInotifySharedMemory() {}
    
    func run() {
        let configuration = ClientConnection(configuration: .default(target: .hostAndPort(address, 8080),
                                                                     eventLoopGroup: MultiThreadedEventLoopGroup(numberOfThreads: 1))
        )
        
        client = DFSServiceNIOClient(channel: configuration)
    }
    
    private func store(_ filename: String) {
        guard let client = client else {
            print("LOG: Tried calling store but client is nil")
            return
        }
        var data = FileRequest()
        data.fileName = "TEST"
        print("sending")
        let status = client.delete(data)
        print(status.response)
    }
}
