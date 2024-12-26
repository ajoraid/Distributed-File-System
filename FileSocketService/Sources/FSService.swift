//
//  FSService.swift
//  FSService
//
//  Created by Adnan Joraid on 2024-12-25.
//

import Foundation
import Vapor
var activeWebSockets: [UUID: WebSocket] = [:]
let lock = NSLock()
@main
struct FSService {
    
    static func main() {
        let application = Application()
        defer { application.shutdown() }
        application.http.server.configuration.port = 8080
        application.webSocket("socket") { req, ws in
            let clientID = UUID()
            lock.lock()
            activeWebSockets[clientID] = ws
            lock.unlock()
            
            print("Client connected: \(clientID)")
            
            ws.onClose.whenComplete { _ in
                lock.lock()
                activeWebSockets.removeValue(forKey: clientID)
                lock.unlock()
            }
            print("Client closed: \(clientID)")
        }
        
        application.post("notify") { req -> HTTPStatus in
            lock.lock()
            for (id, ws) in activeWebSockets {
                ws.send("event")
            }
            lock.unlock()
            return .ok
        }
        do {
            try application.run()
        } catch {
            print(error.localizedDescription)
        }
    }
}
