import UIKit

final class AudioPlayerViewRouterNodeActionAdapter: NodeActionViewControllerDelegate {
    
    private let configEntity: AudioPlayerConfigEntity
    private(set) var nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate?
    private(set) var fileLinkActionViewControllerDelegate: FileLinkActionViewControllerDelegate?
    private var audioPlayerViewControllerDelegate: (any AudioPlayerViewControllerNodeActionForwardingDelegate)?
    
    init(
        configEntity: AudioPlayerConfigEntity,
        nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate?,
        fileLinkActionViewControllerDelegate: FileLinkActionViewControllerDelegate?,
        audioPlayerViewController: UIViewController? = nil
    ) {
        self.configEntity = configEntity
        self.nodeActionViewControllerDelegate = nodeActionViewControllerDelegate
        self.fileLinkActionViewControllerDelegate = fileLinkActionViewControllerDelegate
        
        if let audioPlayerViewController = audioPlayerViewController as? AudioPlayerViewController {
            self.audioPlayerViewControllerDelegate = audioPlayerViewController
        }
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        switch configEntity.nodeOriginType {
        case .folderLink, .chat:
            nodeActionViewControllerDelegate?.nodeAction(nodeAction, didSelect: action, for: node, from: sender)
        case .fileLink:
            fileLinkActionViewControllerDelegate?.nodeAction(nodeAction, didSelect: action, for: node, from: sender)
            
            if let nodeActionTypeEntity = action.toNodeActionTypeEntity() {
                audioPlayerViewControllerDelegate?.didSelectNodeActionTypeMenu(nodeActionTypeEntity)
            }
        case .unknown:
            break
        }
    }
}
