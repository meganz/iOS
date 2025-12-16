import ChatRepo
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPermissions
import UIKit

// MARK: - NodeActionViewControllerDelegate

extension MediaTabHostingController: NodeActionViewControllerDelegate {

    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        let nodeActionViewControllerDelegate: any NodeActionViewControllerDelegate = NodeActionViewControllerGenericDelegate(
            viewController: self,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: self),
            nodeActionListener: nodeActionListener()
        )
        nodeActionViewControllerDelegate.nodeAction?(nodeAction, didSelect: action, for: node, from: sender)
        resetAfterNodeAction()
    }

    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) {
        handleNodesAction(nodeAction, action: action, nodes: nodes, sender: sender)
    }

    private func handleNodesAction(_ nodeAction: NodeActionViewController, action: MegaNodeActionType, nodes: [MEGANode], sender: Any) {
        let nodeActionViewControllerDelegate: any NodeActionViewControllerDelegate = NodeActionViewControllerGenericDelegate(
            viewController: self,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: self),
            nodeActionListener: nodeActionListener()
        )
        switch action {
        case .copy, .move, .shareLink, .manageLink, .exportFile, .sendToChat, .removeLink, .moveToRubbishBin, .download, .saveToPhotos, .hide, .unhide, .addTo, .addToAlbum:
            nodeActionViewControllerDelegate.nodeAction?(nodeAction, didSelect: action, forNodes: nodes, from: sender)
            resetAfterNodeAction()
        default:
            break
        }
    }

    private func nodeActionListener() -> (MegaNodeActionType?, [MEGANode]) -> Void {
        { [weak self] action, _ in
            guard let tracker = self?.tracker else { return }
            switch action {
            case .hide:
                tracker.trackAnalyticsEvent(with: HideNodeMultiSelectMenuItemEvent())
            default:
                break
            }
        }
    }

    private func resetAfterNodeAction() {
        viewModel.editMode = .inactive
    }
}

// MARK: - BrowserViewControllerDelegate

extension MediaTabHostingController: BrowserViewControllerDelegate {

    public func nodeEditCompleted(_ complete: Bool) {
        // Exit edit mode after node editing is complete
        viewModel.editMode = .inactive
    }
}
