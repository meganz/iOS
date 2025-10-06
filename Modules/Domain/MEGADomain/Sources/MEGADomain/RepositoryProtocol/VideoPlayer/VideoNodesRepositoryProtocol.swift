import MEGASwift

public protocol VideoNodesRepositoryProtocol: Sendable, RepositoryProtocol {
    func fetchVideoNodes(for node: some PlayableNode) -> [any PlayableNode]
    func streamVideoNodes(for node: some PlayableNode) -> AnyAsyncSequence<[any PlayableNode]>
}
