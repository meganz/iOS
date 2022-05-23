final class AlbumContentsUpdateNotifierRepository: AlbumContentsUpdateNotifierRepositoryProtocol {
    var onAlbumReload: (() -> Void)?
    
    private let sdk: MEGASdk
    private var nodesUpdateListenerRepo: SDKNodesUpdateListenerProtocol
    
    init(
        sdk: MEGASdk,
        nodesUpdateListenerRepo: SDKNodesUpdateListenerProtocol
    ) {
        self.sdk = sdk
        self.nodesUpdateListenerRepo = nodesUpdateListenerRepo
        
        self.nodesUpdateListenerRepo.onUpdateHandler = { [weak self] nodes in
            self?.checkAlbumForReload(nodes)
        }
    }
    
    private func isAnyNodeMovedIntoTrash(_ nodes: [MEGANode]) -> Bool {
        let trashedNodes = nodes.filter {
            sdk.rubbishNode == $0
        }
        return !trashedNodes.isEmpty
    }
    
    private func checkAlbumForReload(_ nodes: [MEGANode]) {
        let isAnyNodesTrashed = isAnyNodeMovedIntoTrash(nodes)
        let hasNewNodes = nodes.containsNewNode()
        let hasModifiedNodes = nodes.hasModifiedAttributes()
        let hasModifiedParent = nodes.hasModifiedParent()
        let hasSharedLink = nodes.hasSharedLink()
        
        if isAnyNodesTrashed || hasNewNodes || hasModifiedNodes || hasModifiedParent || hasSharedLink {
            onAlbumReload?()
        }
    }
}
