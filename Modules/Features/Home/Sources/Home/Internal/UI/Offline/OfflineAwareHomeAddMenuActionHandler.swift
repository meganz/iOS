import MEGAAppPresentation

/// Wraps the Home add menu's action handler so an action that needs a connection shows the
/// standard no-connection prompt instead of running while offline
///
/// The sheet dismisses itself before handing the action over, so the prompt lands on the Home
/// screen rather than on top of a sheet that is on its way out.
@MainActor
struct OfflineAwareHomeAddMenuActionHandler: HomeAddMenuActionHandling {
    private let handler: any HomeAddMenuActionHandling
    private let offlineActionGuard: any OfflineActionGuarding

    init(
        wrapping handler: any HomeAddMenuActionHandling,
        offlineActionGuard: some OfflineActionGuarding
    ) {
        self.handler = handler
        self.offlineActionGuard = offlineActionGuard
    }

    func handleAction(_ action: HomeAddMenuAction) {
        guard !action.requiresConnection || offlineActionGuard.allowsActionRequiringConnection() else { return }
        handler.handleAction(action)
    }
}
