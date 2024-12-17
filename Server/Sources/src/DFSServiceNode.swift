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

    init(eventLoopGroup: EventLoopGroup, mountPath: String, interceptors: (any DFSServiceServerInterceptorFactoryProtocol)? = nil) {
        self.eventLoopGroup = eventLoopGroup
        self.mountPath = mountPath
        self.interceptors = interceptors
    }
    
    var interceptors: (any DFSServiceServerInterceptorFactoryProtocol)?
    
    func lock(request: FileRequest,
              context: any GRPC.StatusOnlyCallContext) -> NIOCore.EventLoopFuture<EmptyResponse> {
        print("lock called with \(request.fileName)")
        
        return context.eventLoop.makeSucceededFuture(EmptyResponse())
    }
    
    func store(context: GRPC.UnaryResponseCallContext<FileContent>) -> NIOCore.EventLoopFuture<(GRPC.StreamEvent<FileRequest>) -> Void> {
        let handler: (GRPC.StreamEvent<FileRequest>) -> Void = { [weak self] event in
            switch event {
            case .message(let fileRequest):
                guard let self else { return }
                print("Received file chunk: \(fileRequest.fileContent)")
                do {
                    let path = "./\(self.mountPath)/\(fileRequest.fileName)"
                    if !FileManager.default.fileExists(atPath: path) {
                        FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
                    }
                    let fileURL = URL(fileURLWithPath: path)
                    let fileHandle = try FileHandle(forWritingTo: fileURL)
                    fileHandle.seekToEndOfFile()
                    try fileHandle.write(contentsOf: fileRequest.fileContent)
                } catch {
                    print("Error \(error)")
                    return
                }
            case .end:
                print("Stream ended")
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
