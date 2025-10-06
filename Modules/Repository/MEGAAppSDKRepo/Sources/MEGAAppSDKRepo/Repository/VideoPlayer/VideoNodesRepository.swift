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

    public func fetchVideoNodes(for node: some PlayableNode) -> [any PlayableNode] {
        filterForVideos(
            nodeList: sdk.search(
                with: MEGASearchFilter(
                    term: "",
                    parentNodeHandle: node.parentHandle,
                    nodeType: .unknown,
                    category: .video,
                    sensitiveFilter: .disabled,
                    favouriteFilter: .disabled,
                    creationTimeFrame: nil,
                    modificationTimeFrame: nil
                ),
                orderType: .defaultAsc,
                page: nil,
                cancelToken: MEGACancelToken()
            )
        ).toNodeArray()
    }

    public func streamVideoNodes(for node: some PlayableNode) -> AnyAsyncSequence<[any PlayableNode]> {
        nodeUpdatesProvider
            .nodeUpdates
            .filter { $0.isNotEmpty }
            .map { _ in fetchVideoNodes(for: node) }
            .prepend(fetchVideoNodes(for: node))
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
