import MEGADomain
import MEGASwift

public struct MockPhotoBrowserUseCase: PhotoBrowserUseCaseProtocol {
    private let nodeRepository: any NodeRepositoryProtocol
    
    public init(
        nodeRepository: some NodeRepositoryProtocol = MockNodeRepository(
            nodeUpdates: EmptyAsyncSequence().eraseToAnyAsyncSequence()
        )
    ) {
        self.nodeRepository = nodeRepository
    }
    
    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        nodeRepository.nodeUpdates
    }
}
