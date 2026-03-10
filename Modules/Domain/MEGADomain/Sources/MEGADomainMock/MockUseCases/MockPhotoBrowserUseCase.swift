import MEGADomain
import MEGASwift

public struct MockPhotoBrowserUseCase: PhotoBrowserUseCaseProtocol {
    
    private let nodeRepository: any NodeRepositoryProtocol
    private let nodeForFileLinkResult: Result<NodeEntity, any Error>
    
    public init(
        nodeRepository: some NodeRepositoryProtocol = MockNodeRepository(
            nodeUpdates: EmptyAsyncSequence().eraseToAnyAsyncSequence()
        ),
        nodeForFileLinkResult: Result<NodeEntity, any Error> = .success(NodeEntity())
    ) {
        self.nodeRepository = nodeRepository
        self.nodeForFileLinkResult = nodeForFileLinkResult
    }
    
    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        nodeRepository.nodeUpdates
    }
    
    public func nodeFor(fileLink: FileLinkEntity) async throws -> NodeEntity {
        try nodeForFileLinkResult.get()
    }
}
