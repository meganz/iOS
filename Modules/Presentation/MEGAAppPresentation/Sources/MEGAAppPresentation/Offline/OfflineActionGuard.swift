public protocol OfflineActionGuarding: Sendable {
    /// Returns true when an action that needs the network may run. Otherwise shows the
    /// standard no-connection prompt and returns false, so the caller does nothing.
    func allowsActionRequiringConnection() -> Bool
}

/// Blocks actions that cannot work without a connection — remote mutations and starting
/// transfers — while the new offline mode is on (IOS-12228).
///
/// `isReachablePromptingIfNot` both reports reachability and, when offline, shows the prompt:
/// keeping the two in one call means the prompt can never be skipped while the action is
/// blocked. It defaults to whatever the app registered on `DIContainer`, so any screen —
/// including one living in a package — can build a working guard from the feature flag alone.
/// The default reads the registration when the action runs rather than when the guard is
/// built, so a guard constructed before app launch finishes still behaves correctly.
public struct OfflineActionGuard: OfflineActionGuarding {
    private let isNewOfflineModeEnabled: Bool
    private let isReachablePromptingIfNot: @Sendable () -> Bool

    public init(
        isNewOfflineModeEnabled: Bool,
        isReachablePromptingIfNot: @escaping @Sendable () -> Bool = { DIContainer.isReachablePromptingIfNot() }
    ) {
        self.isNewOfflineModeEnabled = isNewOfflineModeEnabled
        self.isReachablePromptingIfNot = isReachablePromptingIfNot
    }

    public func allowsActionRequiringConnection() -> Bool {
        guard isNewOfflineModeEnabled else { return true }
        return isReachablePromptingIfNot()
    }

    /// For the screens that share a type taking a guard but have not adopted offline mode
    /// yet: nothing is blocked. The flag being off short-circuits before reachability is
    /// ever consulted, so the prompt closure here is never called.
    public static var neverBlocking: OfflineActionGuard {
        OfflineActionGuard(isNewOfflineModeEnabled: false)
    }
}
