import MEGASwift

public protocol VideoNodesUseCaseProtocol: Sendable {
    func monitorVideoNodesUpdates(for nodes: [some PlayableNode]) async -> AnyAsyncSequence<[any PlayableNode]>
    func isInRubbishBin(node: some PlayableNode) -> Bool
}

public struct VideoNodesUseCase<T: VideoNodesRepositoryProtocol>: VideoNodesUseCaseProtocol, Sendable {
    private let repo: T

    public init(
        repo: T
    ) {
        self.repo = repo
    }

    public func monitorVideoNodesUpdates(for nodes: [some PlayableNode]) async -> AnyAsyncSequence<[any PlayableNode]> {
        await repo.monitorVideoNodesUpdates(for: nodes)
    }
    
    public func isInRubbishBin(node: some PlayableNode) -> Bool {
        repo.isInRubbishBin(node: node)
    }
}
