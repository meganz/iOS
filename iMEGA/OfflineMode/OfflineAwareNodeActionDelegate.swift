import MEGAAppPresentation

/// Wraps a node action sheet delegate so actions that need a connection show the no-connection
/// prompt instead of running while offline (IOS-12228).
///
/// Both delegates the new Cloud Drive uses — the shared `NodeActionViewControllerGenericDelegate`
/// behind the row and navigation bar "···", and `NodeActionsDelegateHandler` behind the select
/// mode toolbar's "···" — implement this protocol, so wrapping covers all three entry points
/// without changing behaviour on the screens that share those delegates. Any other screen adopting
/// offline mode can wrap its own delegate the same way.
///
/// It stays in the app target because `NodeActionViewController` and `MEGANode` are app-target
/// types; the guard it delegates to lives in MEGAAppPresentation.
@MainActor
final class OfflineAwareNodeActionDelegate: NSObject, NodeActionViewControllerDelegate {
    private let wrapped: any NodeActionViewControllerDelegate
    private let offlineActionGuard: any OfflineActionGuarding

    init(
        wrapping wrapped: some NodeActionViewControllerDelegate,
        offlineActionGuard: some OfflineActionGuarding
    ) {
        self.wrapped = wrapped
        self.offlineActionGuard = offlineActionGuard
    }

    func nodeAction(
        _ nodeAction: NodeActionViewController,
        didSelect action: MegaNodeActionType,
        for node: MEGANode,
        from sender: Any
    ) {
        guard allows(action) else { return }
        wrapped.nodeAction?(nodeAction, didSelect: action, for: node, from: sender)
    }

    func nodeAction(
        _ nodeAction: NodeActionViewController,
        didSelect action: MegaNodeActionType,
        forNodes nodes: [MEGANode],
        from sender: Any
    ) {
        guard allows(action) else { return }
        wrapped.nodeAction?(nodeAction, didSelect: action, forNodes: nodes, from: sender)
    }

    private func allows(_ action: MegaNodeActionType) -> Bool {
        guard action.requiresConnection else { return true }
        return offlineActionGuard.allowsActionRequiringConnection()
    }
}
