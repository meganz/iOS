/// A delegate class that handles node actions and checks for over disk quota conditions.
///
/// It intercepts node actions and checks if the specified action should be blocked due to over disk quota conditions.
final class OverDiskQuotaNodeActionViewControllerDelegate: NodeActionViewControllerDelegate {
    private let delegate: any NodeActionViewControllerDelegate
    private let overDiskQuotaChecker: any OverDiskQuotaChecking
    private let overDiskActions: Set<MegaNodeActionType>
    
    init(
        delegate: some NodeActionViewControllerDelegate,
        overDiskQuotaChecker: some OverDiskQuotaChecking,
        overDiskActions: Set<MegaNodeActionType>
    ) {
        self.delegate = delegate
        self.overDiskQuotaChecker = overDiskQuotaChecker
        self.overDiskActions = overDiskActions
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) {
        guard !showOverDiskQuotaIfNeeded(action: action) else { return }
        delegate.nodeAction?(nodeAction, didSelect: action, forNodes: nodes, from: sender)
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        guard !showOverDiskQuotaIfNeeded(action: action) else { return }
        delegate.nodeAction?(nodeAction, didSelect: action, for: node, from: sender)
    }
    
    private func showOverDiskQuotaIfNeeded(action: MegaNodeActionType) -> Bool {
        overDiskActions.contains(action) && overDiskQuotaChecker.showOverDiskQuotaIfNeeded()
    }
}
