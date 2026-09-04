import MEGAAppPresentation
import MEGADomain
import QuotaWarnings

@MainActor
enum AudioTearDownHandlerFactory {
    static func make(
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase
    ) -> any QuotaDialogDismissHandling {
        if featureFlagProvider.isFeatureFlagEnabled(for: .audioPlayerRevamp) || remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosAudioPlayerRevamp) {
            RevampedAudioTearDownHandler()
        } else {
            LegacyAudioTearDownHandler()
        }
    }
}
