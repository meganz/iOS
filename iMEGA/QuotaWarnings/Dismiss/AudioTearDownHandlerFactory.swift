import MEGAAppPresentation
import QuotaWarnings

@MainActor
enum AudioTearDownHandlerFactory {
    static func make(
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) -> any QuotaDialogDismissHandling {
        if featureFlagProvider.isFeatureFlagEnabled(for: .audioPlayerRevamp) {
            RevampedAudioTearDownHandler()
        } else {
            LegacyAudioTearDownHandler()
        }
    }
}
