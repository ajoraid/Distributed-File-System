//
//  WriterLockMap.swift
//  DFSServer
//
//  Created by Adnan Joraid on 2024-12-17.
//

import Foundation

actor WriterLockMap {
    static let shared = WriterLockMap()
    private init () {}
    private struct FileLockRequest: Hashable {
        let userID: String
        let time: UInt64
        init(userID: String, time: UInt64? = nil) {
            self.userID = userID
            self.time = time ?? UInt64(Date().timeIntervalSince1970 * 1000)
        }
    }
    private var map = [String: FileLockRequest]()
    
    func insert(_ filename: String, _ clientID: String, _ deadline: Int64) -> Bool {
        if let item = map[filename] {
            // The lock was not freed for unknown error. cleanup any lock with t > deadline
            if item.time > deadline {
                map.updateValue(.init(userID: clientID), forKey: filename)
                return true
            }
            return item.userID == clientID
        }
        map[filename] = .init(userID: clientID)
        print(map)
        return true
    }
    
    func remove(_ filename: String) -> Bool {
        if let _ = map[filename] {
            map.removeValue(forKey: filename)
            return true
        }
        return false
    }
}
