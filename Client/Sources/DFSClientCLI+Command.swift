//
//  DFSClientCLI+Command.swift
//  DFSClient
//
//  Created by Adnan Joraid on 2024-12-14.
//

import Foundation
extension DFSClientCLI {
    enum Command {
        case fetch
        case store
        case delete
        case mount
        
        static func fromString(_ string: String) -> Command? {
            switch string {
            case "fetch":
                return .fetch
            case "store":
                return .store
            case "delete":
                return .delete
            case "mount":
                return .mount
            default:
                return nil
            }
        }
    }
}
