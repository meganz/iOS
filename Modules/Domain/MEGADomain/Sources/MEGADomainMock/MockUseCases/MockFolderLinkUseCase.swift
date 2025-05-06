import MEGADomain
import MEGASwift

public final class MockFolderLinkUseCase: FolderLinkUseCaseProtocol {
    public init() { }
    
    public var completedDownloadTransferUpdates: AnyAsyncSequence<HandleEntity> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    public var fetchNodesRequestStartUpdates: AnyAsyncSequence<RequestEntity> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    public var requestFinishUpdates: AnyAsyncSequence<Result<RequestEntity, FolderLinkErrorEntity>> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
}
