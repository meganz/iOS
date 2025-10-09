import MEGASwift

public protocol VideoNodesUseCaseProtocol: Sendable {
    func fetchVideoNodes(for node: some PlayableNode) async -> [any PlayableNode]
    func streamVideoNodes(for node: some PlayableNode) async -> AnyAsyncSequence<[any PlayableNode]>
}

public struct VideoNodesUseCase<T: VideoNodesRepositoryProtocol>: VideoNodesUseCaseProtocol, Sendable {
    private let repo: T

    public init(
        repo: T
    ) {
        self.repo = repo
    }

    public func fetchVideoNodes(for node: some PlayableNode) async -> [any PlayableNode] {
        await repo.fetchVideoNodes(for: node)
    }

    public func streamVideoNodes(for node: some PlayableNode) async -> AnyAsyncSequence<[any PlayableNode]> {
        await repo.streamVideoNodes(for: node)
    }
}
