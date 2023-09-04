final class AudioPlayerViewRouterNodeActionAdapter: NodeActionViewControllerDelegate {
    
    private let configEntity: AudioPlayerConfigEntity
    private(set) var nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate?
    private(set) var fileLinkActionViewControllerDelegate: FileLinkActionViewControllerDelegate?
    
    init(configEntity: AudioPlayerConfigEntity, nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate?, fileLinkActionViewControllerDelegate: FileLinkActionViewControllerDelegate?) {
        self.configEntity = configEntity
        self.nodeActionViewControllerDelegate = nodeActionViewControllerDelegate
        self.fileLinkActionViewControllerDelegate = fileLinkActionViewControllerDelegate
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        switch configEntity.nodeOriginType {
        case .folderLink, .chat:
            nodeActionViewControllerDelegate?.nodeAction(nodeAction, didSelect: action, for: node, from: sender)
        case .fileLink:
            fileLinkActionViewControllerDelegate?.nodeAction(nodeAction, didSelect: action, for: node, from: sender)
        case .unknown:
            break
        }
    }
}
