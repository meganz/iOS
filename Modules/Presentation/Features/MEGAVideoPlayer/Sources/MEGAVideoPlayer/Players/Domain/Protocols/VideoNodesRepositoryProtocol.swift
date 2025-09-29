import MEGASwift

public protocol VideoNodesRepositoryProtocol: Sendable {
    func fetchVideoNodes(for node: some PlayableNode) -> [any PlayableNode]
    func streamVideoNodes(for node: some PlayableNode) -> AnyAsyncSequence<[any PlayableNode]>
}
