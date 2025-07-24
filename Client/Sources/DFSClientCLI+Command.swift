//
//  DFSClientCLI+Command.swift
//  DFSClient
//
//  Created by Adnan Joraid on 2024-12-14.
//

import Foundation
extension DFSClientCLI {
    enum Command: String {
        case fetch
        case store
        case delete
        case mount

        static func fromString(_ string: String) -> Command? {
            return Command(rawValue: string.lowercased())
        }
    }
}
