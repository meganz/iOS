import MEGADomain

final class AlbumContentsUpdateNotifierRepository: AlbumContentsUpdateNotifierRepositoryProtocol {
    var onAlbumReload: (() -> Void)?
    
    private let sdk: MEGASdk
    private var nodesUpdateListenerRepo: NodesUpdateListenerProtocol
    
    init(
        sdk: MEGASdk,
        nodesUpdateListenerRepo: NodesUpdateListenerProtocol
    ) {
        self.sdk = sdk
        self.nodesUpdateListenerRepo = nodesUpdateListenerRepo
        
        self.nodesUpdateListenerRepo.onNodesUpdateHandler = { [weak self] nodes in
            self?.checkAlbumForReload(nodes)
        }
    }
    
    private func isAnyNodeMovedIntoTrash(_ nodes: [NodeEntity]) -> Bool {
        guard let rubbishNode = self.sdk.rubbishNode else { return false }
        
        let rubbishNodeEntity = rubbishNode.toNodeEntity()
        
        return nodes.contains(rubbishNodeEntity)
    }
    
    private func checkAlbumForReload(_ nodes: [NodeEntity]) {
        let isAnyNodesTrashed = isAnyNodeMovedIntoTrash(nodes)
        let hasNewNodes = nodes.containsNewNode()
        let hasModifiedNodes = nodes.hasModifiedAttributes()
        let hasModifiedParent = nodes.hasModifiedParent()
        let hasModifiedPublicLink = nodes.hasModifiedPublicLink()
        
        if isAnyNodesTrashed || hasNewNodes ||
            hasModifiedNodes || hasModifiedParent ||
            hasModifiedPublicLink {
            onAlbumReload?()
        }
    }
}
