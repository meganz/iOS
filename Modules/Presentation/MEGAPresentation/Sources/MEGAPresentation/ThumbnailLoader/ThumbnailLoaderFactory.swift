import MEGADomain
import MEGASDKRepo

/// Loader factory to provide the correct thumbnail loader for feature flag
public enum ThumbnailLoaderFactory {
    
    public enum Configuration {
        /// Configuration used to create a General Purpose ThumbnailLoader
        /// This variation will generate URLImageContainers and ImageContainers
        case general
        /// Configuration used to create a SensitiveThumbnailLoader
        /// This variation will generate variations adhering to SensitiveImageContaining and ImageContainers
        case sensitive(sensitiveNodeUseCase: SensitiveNodeUseCaseProtocol)
    }
    
    public static func makeThumbnailLoader(
        config: Configuration,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) -> any ThumbnailLoaderProtocol {
        
        switch config {
        case .general:
            makeThumbnailLoader(thumbnailUseCase: thumbnailUseCase)
        case let .sensitive(sensitiveNodeUseCase) where featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes):
            makeSensitiveThumbnailLoader(
                thumbnailUseCase: thumbnailUseCase,
                sensitiveNodeUseCase: sensitiveNodeUseCase)
        default:
            makeThumbnailLoader(thumbnailUseCase: thumbnailUseCase)
        }
    }
    
    private static func makeSensitiveThumbnailLoader(thumbnailUseCase: some ThumbnailUseCaseProtocol, sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol) -> some ThumbnailLoaderProtocol {
        SensitiveThumbnailLoader(
            thumbnailLoader: ThumbnailLoaderFactory.makeThumbnailLoader(thumbnailUseCase: thumbnailUseCase),
            sensitiveNodeUseCase: sensitiveNodeUseCase)
    }
    
    private static func makeThumbnailLoader(thumbnailUseCase: some ThumbnailUseCaseProtocol) -> some ThumbnailLoaderProtocol {
        ThumbnailLoader(thumbnailUseCase: thumbnailUseCase)
    }
}
