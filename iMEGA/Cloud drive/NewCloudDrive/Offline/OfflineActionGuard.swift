protocol OfflineActionGuarding: Sendable {
    /// Returns true when an action that needs the network may run. Otherwise shows the
    /// standard no-connection prompt and returns false, so the caller does nothing.
    func allowsActionRequiringConnection() -> Bool
}

/// Blocks actions that cannot work without a connection — remote mutations and starting
/// transfers — while the new offline mode is on (IOS-12228).
///
/// Reachability and the prompt come from `MEGAReachabilityManager.isReachableHUDIfNot()`, the
/// convention used throughout the app: it reports reachability and, when offline, shows the
/// "No internet connection" HUD (or the mobile-data-restricted alert). Keeping both in one call
/// means the prompt can never be skipped while the action is blocked.
struct OfflineActionGuard: OfflineActionGuarding {
    private let isNewOfflineModeEnabled: Bool
    private let isReachablePromptingIfNot: @Sendable () -> Bool

    init(
        isNewOfflineModeEnabled: Bool,
        isReachablePromptingIfNot: @escaping @Sendable () -> Bool = { MEGAReachabilityManager.isReachableHUDIfNot() }
    ) {
        self.isNewOfflineModeEnabled = isNewOfflineModeEnabled
        self.isReachablePromptingIfNot = isReachablePromptingIfNot
    }

    func allowsActionRequiringConnection() -> Bool {
        guard isNewOfflineModeEnabled else { return true }
        return isReachablePromptingIfNot()
    }

    /// For the screens outside Cloud Drive that share a type taking a guard: nothing is blocked.
    static var neverBlocking: OfflineActionGuard {
        OfflineActionGuard(isNewOfflineModeEnabled: false)
    }
}
