import MEGASwift

public protocol VideoNodesRepositoryProtocol: Sendable, RepositoryProtocol {
    func monitorVideoNodesUpdates(for nodes: [some PlayableNode]) async -> AnyAsyncSequence<[any PlayableNode]>
    func isInRubbishBin(node: some PlayableNode) -> Bool
}
