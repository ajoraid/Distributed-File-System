//
//  DFSClient.swift
//  DFSClient
//
//  Created by Adnan Joraid on 2024-12-14.
//

import Foundation

class DFSClient {
    private let address: String
    private let mountPath: String
    private let timeout: Int
    
    init(address: String, mountPath: String, timeout: Int) {
        self.address = address
        self.mountPath = mountPath
        self.timeout = timeout
    }
    
    func processCommand(for command: DFSClientCLI.Command, fileName: String) {
        switch command {
        case .fetch:
            print("Call Fetch")
        case .store:
            print("Call Store")
        case .delete:
            print("Call Delete")
        case .mount:
            print("Mount here")
        }
    }
}
