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
    
    public var requestTemporaryErrorUpdates: AnyAsyncSequence<RequestResponseEntity> {
        MEGAUpdateHandlerManager.shared.requestTemporaryErrorUpdates
    }
    
    public var requestFinishUpdates: AnyAsyncSequence<RequestResponseEntity> {
        MEGAUpdateHandlerManager.shared.requestFinishUpdates
    }
    
    public var folderLinkRequestStartUpdates: AnyAsyncSequence<RequestEntity> {
        MEGAUpdateHandlerManager.sharedFolderLink.requestStartUpdates
    }
    
    public var folderLinkRequestFinishUpdates: AnyAsyncSequence<RequestResponseEntity> {
        MEGAUpdateHandlerManager.sharedFolderLink.requestFinishUpdates
    }
}
