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

    public func fetchVideoNodes(for node: some PlayableNode) async -> [any PlayableNode] {
        guard let parentNode = await sdk.node(for: node.parentHandle) else {
            return []
        }

        let childrenNodeList = sdk.children(forParent: parentNode)

        return filterForVideos(nodeList: childrenNodeList).toNodeArray()
    }

    public func streamVideoNodes(for node: some PlayableNode) async -> AnyAsyncSequence<[any PlayableNode]> {
        nodeUpdatesProvider
            .nodeUpdates
            .filter { $0.isNotEmpty }
            .map { _ in await fetchVideoNodes(for: node) }
            .prepend( await fetchVideoNodes(for: node))
            .eraseToAnyAsyncSequence()
    }

    private func filterForVideos(nodeList: MEGANodeList) -> MEGANodeList {
        let newNodeList = MEGANodeList()
        for index in 0..<nodeList.size {
            guard let node = nodeList.node(at: index) else { continue }
            guard isVideoType(node) else { continue }

            newNodeList.add(node)
        }
        return newNodeList
    }

    private func isVideoType(_ node: MEGANode) -> Bool {
        guard let fileExtension = node.name?.pathExtension else {
            return false
        }

        return fileExtension.fileExtensionGroup.isVideo
    }
}
