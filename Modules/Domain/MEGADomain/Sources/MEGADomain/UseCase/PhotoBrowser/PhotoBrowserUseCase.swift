import MEGASwift

public protocol PhotoBrowserUseCaseProtocol: Sendable {
    var nodeUpdates: AnyAsyncSequence<[NodeEntity]> { get }
}

public struct PhotoBrowserUseCase<N: NodeRepositoryProtocol>: PhotoBrowserUseCaseProtocol {
    private let nodeRepository: N
    
    public init(nodeRepository: N) {
        self.nodeRepository = nodeRepository
    }
    
    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        nodeRepository.nodeUpdates
    }
}
