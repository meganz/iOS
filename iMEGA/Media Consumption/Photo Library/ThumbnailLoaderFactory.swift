import MEGADomain
import MEGAPresentation
import MEGASDKRepo

/// Loader factory to provide the correct thumbnail loader for feature flag
struct ThumbnailLoaderFactory {
    static func makeThumbnailLoader(
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
        mode: PhotoLibraryContentMode? = nil
    ) -> any ThumbnailLoaderProtocol {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes),
              [PhotoLibraryContentMode.albumLink, .mediaDiscoveryFolderLink].notContains(mode) else {
            return makeThumbnailLoader(mode: mode)
        }
        return makeSensitiveThumbnailLoader(mode: mode)
    }
    
    private static func makeSensitiveThumbnailLoader(mode: PhotoLibraryContentMode? = nil) -> some ThumbnailLoaderProtocol {
        SensitiveThumbnailLoader(thumbnailLoader: ThumbnailLoaderFactory.makeThumbnailLoader(mode: mode),
                                 nodeUseCaseProtocol: NodeUseCase(
                                    nodeDataRepository: NodeDataRepository.newRepo,
                                    nodeValidationRepository: NodeValidationRepository.newRepo,
                                    nodeRepository: NodeRepository.newRepo))
    }
    
    private static func makeThumbnailLoader(mode: PhotoLibraryContentMode? = nil) -> some ThumbnailLoaderProtocol {
        let thumbnailUseCase = if let mode {
            ThumbnailUseCase.makeThumbnailUseCase(mode: mode)
        } else {
            ThumbnailUseCase(repository: ThumbnailRepository.newRepo)
        }
        return ThumbnailLoader(thumbnailUseCase: thumbnailUseCase)
    }
}
