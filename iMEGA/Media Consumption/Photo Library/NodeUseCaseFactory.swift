import MEGADomain
import MEGAPresentation
import MEGASDKRepo

struct NodeUseCaseFactory {
    static func makeNodeUseCase(
        for mode: PhotoLibraryContentMode,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase
    ) -> (any NodeUseCaseProtocol)? {
        guard remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes),
              [PhotoLibraryContentMode.library, .album, .mediaDiscovery].contains(mode) else {
            return nil
        }
        return NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo)
    }
}
