class DFSServiceNode: DFSServiceProvider {
    let eventLoopGroup: EventLoopGroup

    init(eventLoopGroup: EventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
    }
    var interceptors: (any DFSServiceServerInterceptorFactoryProtocol)?
    
    func lock(request: FileRequest,
              context: any GRPC.StatusOnlyCallContext) -> NIOCore.EventLoopFuture<EmptyResponse> {
        print("lock called with \(request.fileName)")
        
        return context.eventLoop.makeSucceededFuture(EmptyResponse())
    }
    
    func store(context: GRPC.UnaryResponseCallContext<FileContent>) -> NIOCore.EventLoopFuture<(GRPC.StreamEvent<FileRequest>) -> Void> {
        let handler: (GRPC.StreamEvent<FileRequest>) -> Void = { event in
            switch event {
            case .message(let fileRequest):
                print(fileRequest.fileName)
            case .end:
                print("stream ended")
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
        print("we are here! delete got called with \(request.fileName)")
        let response = EmptyResponse()
        return context.eventLoop.makeSucceededFuture(response)
        
    }
}