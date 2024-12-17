//
//  File.swift
//  DFSServer
//
//  Created by Adnan Joraid on 2024-12-16.
//

import Foundation
import GRPC
import NIOCore
import NIOPosix
class DFSServer {
    
    private let address: String
    private let mountPath: String
    private let timeout: Int
    
    init(address: String, mountPath: String, timeout: Int) {
        self.address = address
        self.mountPath = mountPath
        self.timeout = timeout
    }
    
    func run() throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        defer { try? group.syncShutdownGracefully() }
        
        let service = DFSServiceNode(eventLoopGroup: group, mountPath: mountPath)
        let server = try Server.insecure(group: group)
            .withServiceProviders([service])
            .bind(host: address, port: 27000)
            .wait()
        
        
        print("Server is listening on \(address):\(27000)")
        
        try server.onClose.wait()
    }
}



