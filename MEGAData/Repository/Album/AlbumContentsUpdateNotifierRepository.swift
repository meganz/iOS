import Combine
import MEGADomain

final class AlbumContentsUpdateNotifierRepository: NSObject, AlbumContentsUpdateNotifierRepositoryProtocol {
    static var newRepo = AlbumContentsUpdateNotifierRepository(sdk: MEGASdk.shared)
    
    private let albumReloadSourcePublisher = PassthroughSubject<Void, Never>()
    private let sdk: MEGASdk
    
    var albumReloadPublisher: AnyPublisher<Void, Never> {
        albumReloadSourcePublisher.eraseToAnyPublisher()
    }
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
        super.init()
        sdk.add(self)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    private func isAnyNodeMovedIntoTrash(_ nodes: [NodeEntity]) -> Bool {
        guard let rubbishNode = self.sdk.rubbishNode else { return false }
        
        let rubbishNodeEntity = rubbishNode.toNodeEntity()
        
        return nodes.contains(rubbishNodeEntity)
    }
    
    private func shouldAlbumReload(_ nodes: [NodeEntity]) -> Bool {
        let isAnyNodesTrashed = isAnyNodeMovedIntoTrash(nodes)
        let hasNewNodes = nodes.containsNewNode()
        let hasModifiedNodes = nodes.hasModifiedAttributes()
        let hasModifiedParent = nodes.hasModifiedParent()
        let hasModifiedPublicLink = nodes.hasModifiedPublicLink()
        
        return isAnyNodesTrashed || hasNewNodes ||
            hasModifiedNodes || hasModifiedParent ||
            hasModifiedPublicLink
    }
}

extension AlbumContentsUpdateNotifierRepository: MEGAGlobalDelegate {
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard let updatedNodes = nodeList?.toNodeEntities(),
        shouldAlbumReload(updatedNodes) else { return }
        albumReloadSourcePublisher.send()
    }
}
