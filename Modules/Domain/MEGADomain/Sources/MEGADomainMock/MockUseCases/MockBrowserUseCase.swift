import MEGADomain
import MEGASwift

public struct MockBrowserUseCase: BrowserUseCaseProtocol {
    public let nodeUpdates: AnyAsyncSequence<[NodeEntity]>
    public let copyRequestStartUpdates: AnyAsyncSequence<Void>
    public let requestFinishUpdates: AnyAsyncSequence<RequestEntity>
    
    public init(
        nodeUpdates: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        copyRequestStartUpdates: AnyAsyncSequence<Void> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        requestFinishUpdates: AnyAsyncSequence<RequestEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.nodeUpdates = nodeUpdates
        self.copyRequestStartUpdates = copyRequestStartUpdates
        self.requestFinishUpdates = requestFinishUpdates
    }
}
