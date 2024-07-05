import MEGASdk

extension VideoPlaylistContentViewController: NodeActionViewControllerDelegate {
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        let nodeActionViewControllerDelegate: any NodeActionViewControllerDelegate = NodeActionViewControllerGenericDelegate(
            viewController: self,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: self)
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
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: self)
        )
        switch action {
        case .download, .manageLink, .saveToPhotos:
            nodeActionViewControllerDelegate.nodeAction?(nodeAction, didSelect: action, forNodes: nodes, from: sender)
            resetNavigationBar()
        default:
            break
        }
    }
}