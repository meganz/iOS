import MEGASwift

public protocol VideoNodesRepositoryProtocol: Sendable, RepositoryProtocol {
    func fetchVideoNodes(for node: some PlayableNode) async -> [any PlayableNode]
    func streamVideoNodes(for node: some PlayableNode) async -> AnyAsyncSequence<[any PlayableNode]>
}
