import Foundation
import MEGADomain
import MEGASwift

public class MockVideoNodesUseCase: VideoNodesUseCaseProtocol, @unchecked Sendable {
    public let nodesUpdate: [any PlayableNode]
    public var monitorNodesUpdatesCallCount = 0
    public let isInRubbishBin: Bool

    public init(
        nodesUpdate: [any PlayableNode] = [],
        isInRubbishBin: Bool = false
    ) {
        self.nodesUpdate = nodesUpdate
        self.isInRubbishBin = isInRubbishBin
    }

    public func monitorVideoNodesUpdates(for nodes: [some PlayableNode]) -> AnyAsyncSequence<[any PlayableNode]> {
        monitorNodesUpdatesCallCount += 1
        return AsyncStream<[any PlayableNode]> { continuation in
            continuation.yield(nodesUpdate)
            continuation.finish()
        }.eraseToAnyAsyncSequence()
    }

    public func isInRubbishBin(node: some PlayableNode) -> Bool {
        isInRubbishBin
    }
}
