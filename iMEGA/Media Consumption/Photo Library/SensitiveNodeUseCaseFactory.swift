import MEGADomain
import MEGAPresentation
import MEGASDKRepo

struct SensitiveNodeUseCaseFactory {
    static func makeSensitiveNodeUseCase(
        for mode: PhotoLibraryContentMode,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) -> (any SensitiveNodeUseCaseProtocol)? {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes),
              [PhotoLibraryContentMode.library, .album, .mediaDiscovery].contains(mode) else {
            return nil
        }
        return SensitiveNodeUseCase(
            nodeRepository: NodeRepository.newRepo,
            accountUseCase: AccountUseCase(
                repository: AccountRepository.newRepo))
    }
}
