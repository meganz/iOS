import MEGADomain
import MEGAPresentation
import MEGASDKRepo

public struct SensitiveNodeUseCaseFactory {
    public static func makeSensitiveNodeUseCase(
        for mode: PhotoLibraryContentMode,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase,
        configuration: ContentLibraries.Configuration = ContentLibraries.configuration
    ) -> (any SensitiveNodeUseCaseProtocol)? {
        guard remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes),
              [PhotoLibraryContentMode.library, .album, .mediaDiscovery].contains(mode) else {
            return nil
        }
        return configuration.sensitiveNodeUseCase
    }
}
