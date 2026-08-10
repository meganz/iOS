import MEGADomain
import MEGAL10n

final class RubbishBinMenuDelegateHandler: RubbishBinMenuDelegate {
    
    let restore: (NodeEntity) -> Void
    let showNodeInfo: (_ node: NodeEntity) -> Void
    let showNodeVersions: (NodeEntity) -> Void
    let remove: (NodeEntity) -> Void
    let nodeSource: NodeSource
    
    private let offlineActionGuard: any OfflineActionGuarding

    init(
        restore: @escaping (NodeEntity) -> Void,
        offlineActionGuard: some OfflineActionGuarding,
        showNodeInfo: @escaping (_ node: NodeEntity) -> Void,
        showNodeVersions: @escaping (NodeEntity) -> Void,
        remove: @escaping (NodeEntity) -> Void,
        nodeSource: NodeSource
    ) {
        self.restore = restore
        self.offlineActionGuard = offlineActionGuard
        self.showNodeInfo = showNodeInfo
        self.showNodeVersions = showNodeVersions
        self.remove = remove
        
        self.nodeSource = nodeSource
    }
    
    func rubbishBinMenu(didSelect action: RubbishBinActionEntity) {
        guard action.requiresConnection == false || offlineActionGuard.allowsActionRequiringConnection() else { return }

        guard
            case let .node(nodeProvider) = nodeSource,
            let parentNode = nodeProvider()
        else { return }
        
        switch action {
        case .restore:
            restore(parentNode)
        case .info:
            showNodeInfo(parentNode)
        case .versions:
            showNodeVersions(parentNode)
        case .remove:
            remove(parentNode)
        }
    }
    
}
