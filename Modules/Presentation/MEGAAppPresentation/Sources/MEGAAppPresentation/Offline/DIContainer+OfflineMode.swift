import MEGASwift

// MARK: - Offline mode

public extension DIContainer {
    /// Reports reachability and, when offline, shows the standard no-connection prompt.
    ///
    /// Both must happen in one call: an action blocked without a prompt reads as a dead tap.
    ///
    /// The app registers its own at launch — `MEGAReachabilityManager.isReachableHUDIfNot()`,
    /// the convention used throughout the app, which also covers the mobile-data-restricted
    /// alert. That cannot live here: it presents an HUD, reads the Core Telephony restricted
    /// state, and is declared in the app target's Objective-C headers.
    ///
    /// The default never blocks, so a target that registers nothing — the extensions, and any
    /// test that does not care — behaves exactly as it did before offline mode existed.
    ///
    /// Written once at launch and read from whichever context a guarded action runs in, so the
    /// storage is synchronised rather than declared `nonisolated(unsafe)`. `@MainActor` would be
    /// the truthful isolation — the prompt presents UI — but the guard is consumed by handlers
    /// that are not main-actor isolated today, so requiring it here would not compile.
    static var isReachablePromptingIfNot: @Sendable () -> Bool {
        get { reachabilityPrompt.wrappedValue }
        set { reachabilityPrompt.mutate { $0 = newValue } }
    }

    private static let reachabilityPrompt = Atomic<@Sendable () -> Bool>(wrappedValue: { true })
}
