import Foundation
import MEGADomain
import MEGASwift

public struct MockVideoNodesUseCase: VideoNodesUseCaseProtocol, @unchecked Sendable {
    public let nodes: [any PlayableNode]

    public init(nodes: [any PlayableNode] = []) {
        self.nodes = nodes
    }

    public func fetchVideoNodes(for node: some PlayableNode) -> [any PlayableNode] {
        nodes
    }

    public func streamVideoNodes(for node: some PlayableNode) -> AnyAsyncSequence<[any PlayableNode]> {
        return AsyncStream<[any PlayableNode]> { continuation in
            continuation.yield(nodes)
            continuation.finish()
        }.eraseToAnyAsyncSequence()
    }
}
