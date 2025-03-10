import MEGADomain
import MEGASdk
import MEGASwift

public protocol RequestProviderProtocol: Sendable {
    var requestStartUpdates: AnyAsyncSequence<RequestEntity> { get }
    var requestUpdates: AnyAsyncSequence<RequestEntity> { get }
    var requestTemporaryErrorUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>> { get }
    var requestFinishUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>> { get }
}

public struct RequestProvider: RequestProviderProtocol {
    public var requestStartUpdates: AnyAsyncSequence<RequestEntity> {
        MEGAUpdateHandlerManager.shared.requestStartUpdates
    }
    
    public var requestUpdates: AnyAsyncSequence<RequestEntity> {
        MEGAUpdateHandlerManager.shared.requestUpdates
    }
    
    public var requestTemporaryErrorUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>> {
        MEGAUpdateHandlerManager.shared.requestTemporaryErrorUpdates
    }
    
    public var requestFinishUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>> {
        MEGAUpdateHandlerManager.shared.requestFinishUpdates
    }
    
    public init() { }
}
