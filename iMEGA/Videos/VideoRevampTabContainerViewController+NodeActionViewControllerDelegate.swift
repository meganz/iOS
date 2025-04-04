import ChatRepo
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPermissions

extension VideoRevampTabContainerViewController: NodeActionViewControllerDelegate {
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        let nodeActionViewControllerDelegate: any NodeActionViewControllerDelegate = NodeActionViewControllerGenericDelegate(
            viewController: self,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: self),
            nodeActionListener: nodeActionListener(tracker: tracker)
        )
        nodeActionViewControllerDelegate.nodeAction?(nodeAction, didSelect: action, for: node, from: sender)
        resetNavigationBar()
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) {
        handleNodesAction(nodeAction, action: action, nodes: nodes, sender: sender)
    }
    
    private func handleNodesAction(_ nodeAction: NodeActionViewController, action: MegaNodeActionType, nodes: [MEGANode], sender: Any) {
        let nodeActionViewControllerDelegate: any NodeActionViewControllerDelegate = NodeActionViewControllerGenericDelegate(
            viewController: self,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: self),
            nodeActionListener: nodeActionListener(tracker: tracker)
        )
        switch action {
        case .copy, .move, .shareLink, .manageLink, .exportFile, .sendToChat, .removeLink, .moveToRubbishBin, .download, .saveToPhotos, .hide, .unhide, .addTo, .addToAlbum:
            nodeActionViewControllerDelegate.nodeAction?(nodeAction, didSelect: action, forNodes: nodes, from: sender)
            resetNavigationBar()
        default:
            break
        }
    }
    
    private func nodeActionListener(tracker: any AnalyticsTracking) -> (MegaNodeActionType?) -> Void {
        { action in
            switch action {
            case .hide:
                tracker.trackAnalyticsEvent(with: HideNodeMultiSelectMenuItemEvent())
            default:
                break // we do not track other events here yet
            }
        }
    }
}
