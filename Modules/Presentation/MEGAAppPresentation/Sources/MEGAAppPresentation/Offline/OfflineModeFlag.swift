public extension FeatureFlagProviderProtocol {
    /// Single gate for the new offline mode (connectivity banner, browsable offline list,
    /// offline open/mutation guards — see IOS-12224). Every screen adopting offline mode reads
    /// it from here, so none of them has to know which flag key stands for the feature.
    ///
    /// Disabled (default, and always in release builds for now) keeps the current behaviour:
    /// the full-page "No internet connection" cover. The safe default lives in the app's
    /// `FeatureFlagProvider`, which is the type that knows the build configuration.
    var isNewOfflineModeEnabled: Bool {
        isFeatureFlagEnabled(for: .offlineMode)
    }
}
