import MEGADomain
import MEGAPresentation
import MEGASDKRepo

struct SensitiveNodeUseCaseFactory {
    static func makeSensitiveNodeUseCase(
        for mode: PhotoLibraryContentMode,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase
    ) -> (any SensitiveNodeUseCaseProtocol)? {
        guard remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes),
              [PhotoLibraryContentMode.library, .album, .mediaDiscovery].contains(mode) else {
            return nil
        }
        return SensitiveNodeUseCase(
            nodeRepository: NodeRepository.newRepo,
            accountUseCase: AccountUseCase(
                repository: AccountRepository.newRepo))
    }
}
