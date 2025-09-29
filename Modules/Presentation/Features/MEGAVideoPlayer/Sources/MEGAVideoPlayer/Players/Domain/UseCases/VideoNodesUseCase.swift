import MEGAAppSDKRepo
import MEGASdk
import MEGASwift

public protocol VideoNodesUseCaseProtocol {
    func fetchVideoNodes(for node: some PlayableNode) -> [any PlayableNode]
    func streamVideoNodes(for node: some PlayableNode) -> AnyAsyncSequence<[any PlayableNode]>
}

public struct VideoNodesUseCase<T: VideoNodesRepositoryProtocol>: VideoNodesUseCaseProtocol, Sendable {
    private let repo: T

    public init(
        repo: T
    ) {
        self.repo = repo
    }

    public func fetchVideoNodes(for node: some PlayableNode) -> [any PlayableNode] {
        repo.fetchVideoNodes(for: node)
    }

    public func streamVideoNodes(for node: some PlayableNode) -> AnyAsyncSequence<[any PlayableNode]> {
        repo.streamVideoNodes(for: node)
    }
}
