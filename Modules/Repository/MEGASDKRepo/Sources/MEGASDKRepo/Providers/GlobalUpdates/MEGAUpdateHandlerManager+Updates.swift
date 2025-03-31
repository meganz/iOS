import MEGADomain
import MEGASdk
import MEGASwift

extension MEGAUpdateHandlerManager {
    var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onNodesUpdate: { continuation.yield($0) })
            
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }
        .eraseToAnyAsyncSequence()
    }
    
    var userUpdates: AnyAsyncSequence<[UserEntity]> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onUsersUpdate: { continuation.yield($0) })
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }.eraseToAnyAsyncSequence()
    }
    
    var requestStartUpdates: AnyAsyncSequence<RequestEntity> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onRequestStart: { continuation.yield($0) })
            
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }
        .eraseToAnyAsyncSequence()
    }
    
    var requestUpdates: AnyAsyncSequence<RequestEntity> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onRequestUpdate: { continuation.yield($0) })
            
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }
        .eraseToAnyAsyncSequence()
    }
    
    var requestTemporaryErrorUpdates: AnyAsyncSequence<RequestResponseEntity> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onRequestTemporaryError: { continuation.yield($0) })
            
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }
        .eraseToAnyAsyncSequence()
    }
    
    var requestFinishUpdates: AnyAsyncSequence<RequestResponseEntity> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onRequestFinish: { continuation.yield($0) })
            
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }
        .eraseToAnyAsyncSequence()
    }
    
    var transferFinishUpdates: AnyAsyncSequence<Result<TransferEntity, ErrorEntity>> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onTransferFinish: { continuation.yield($0) })
            
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }
        .eraseToAnyAsyncSequence()
    }
}
