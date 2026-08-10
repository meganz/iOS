import MEGAAppPresentation

/// Single gate for the new Cloud Drive offline mode (connectivity banner, browsable
/// offline list, offline open/mutation guards — see IOS-12224).
/// Disabled (default, and always in release builds for now) keeps the current
/// behaviour: the full-page "No internet connection" cover.
///
/// A remote feature flag will be combined here for the staged rollout (IOS-12229),
/// so call sites never need to change.
enum CloudDriveOfflineModeGate {
    static var isNewOfflineModeEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .offlineMode)
    }
}
