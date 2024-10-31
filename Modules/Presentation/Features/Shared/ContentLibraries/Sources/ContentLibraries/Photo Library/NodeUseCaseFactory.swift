import MEGADomain
import MEGAPresentation
import MEGASDKRepo

public struct NodeUseCaseFactory {
    public static func makeNodeUseCase(
        for mode: PhotoLibraryContentMode,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase,
        configuration: ContentLibraries.Configuration = ContentLibraries.configuration
    ) -> (any NodeUseCaseProtocol)? {
        guard remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes),
              [PhotoLibraryContentMode.library, .album, .mediaDiscovery].contains(mode) else {
            return nil
        }
        return configuration.nodeUseCase
    }
}
