import Foundation
import MEGASdk

/// Since the naming of NodeActionViewControllerGenericDelegate suggests its generic usage,
/// This CloudDriveNodeActionViewControllerDelegate was born to wrap it and provide custom logic for Cloud drive.
final class CloudDriveNodeActionViewControllerDelegate: NodeActionViewControllerDelegate {
    private let nodeActionGenericDelegate: NodeActionViewControllerGenericDelegate
    private let nodeActions: NodeActions
    
    init(nodeActionGenericDelegate: NodeActionViewControllerGenericDelegate, nodeActions: NodeActions) {
        self.nodeActionGenericDelegate = nodeActionGenericDelegate
        self.nodeActions = nodeActions
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        switch action {
        case .moveToRubbishBin:
            moveToRubbishBin(node: node)
        default:
            nodeActionGenericDelegate.nodeAction(nodeAction, didSelect: action, for: node, from: sender)
        }
    }

    private func moveToRubbishBin(node: MEGANode) {
        nodeActions.moveToRubbishBin([node.toNodeEntity()])
    }
}
