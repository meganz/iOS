import MEGADomain
import MEGASwift

public struct RequestStatesRepository: RequestStatesRepositoryProtocol {
    public static var newRepo: RequestStatesRepository {
        RequestStatesRepository()
    }
    
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
}
