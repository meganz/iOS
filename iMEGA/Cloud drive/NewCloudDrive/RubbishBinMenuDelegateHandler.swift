import MEGADomain
import MEGAL10n

final class RubbishBinMenuDelegateHandler: RubbishBinMenuDelegate {
    
    let restore: (NodeEntity) -> Void
    let showNodeInfo: (_ node: NodeEntity) -> Void
    let showNodeVersions: (NodeEntity) -> Void
    let remove: (NodeEntity) -> Void
    let nodeSource: NodeSource
    
    init(
        restore: @escaping (NodeEntity) -> Void,
        showNodeInfo: @escaping (_ node: NodeEntity) -> Void,
        showNodeVersions: @escaping (NodeEntity) -> Void,
        remove: @escaping (NodeEntity) -> Void,
        nodeSource: NodeSource
    ) {
        self.restore = restore
        self.showNodeInfo = showNodeInfo
        self.showNodeVersions = showNodeVersions
        self.remove = remove
        
        self.nodeSource = nodeSource
    }
    
    func rubbishBinMenu(didSelect action: RubbishBinActionEntity) {
        
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
