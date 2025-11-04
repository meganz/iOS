import MEGADomain
import MEGASdk
import MEGASwift

public struct VideoNodesRepository: VideoNodesRepositoryProtocol, Sendable {
    public static var newRepo: VideoNodesRepository {
        VideoNodesRepository(
            sdk: .sharedSdk,
            nodeUpdatesProvider: NodeUpdatesProvider()
        )
    }

    private let sdk: MEGASdk

    private let nodeUpdatesProvider: any NodeUpdatesProviderProtocol

    public init(
        sdk: MEGASdk,
        nodeUpdatesProvider: some NodeUpdatesProviderProtocol
    ) {
        self.sdk = sdk
        self.nodeUpdatesProvider = nodeUpdatesProvider
    }

    public func monitorVideoNodesUpdates(for nodes: [some PlayableNode]) async -> AnyAsyncSequence<[any PlayableNode]> {
        return nodeUpdatesProvider
            .nodeUpdates
            .filter { $0.isNotEmpty }
            .map { allNodes in
                let allVideoNodes = allNodes.filter {
                    $0.fileExtensionGroup.isVideo
                }
                let updatedPlayableNodes = allVideoNodes.filter { videoNode in
                    nodes.contains(where: { $0.handle == videoNode.handle })
                }
                return updatedPlayableNodes.toMEGANodes(in: sdk)
            }
            .eraseToAnyAsyncSequence()
    }

    public func isInRubbishBin(node: some PlayableNode) -> Bool {
        guard let node = sdk.node(forHandle: node.handle) else {
            return false
        }

        return sdk.isNode(inRubbish: node)
    }
}
