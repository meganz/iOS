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
        case sensitive(sensitiveNodeUseCase: SensitiveNodeUseCaseProtocol,
                       accountUseCase: AccountUseCaseProtocol)
        
        /// Configuration used to create a General Purpose ThumbnailLoader with fallback icon if failed to generate the icon
        /// This variation will generate URLImageContainers and ImageContainers
        case generalWithFallBackIcon(nodeIconUseCase: NodeIconUsecaseProtocol)
        
        /// Configuration used to create a SensitiveThumbnailLoader with fallback icon if failed to generate the icon
        /// This variation will generate variations adhering to SensitiveImageContaining and ImageContainers
        case sensitiveWithFallbackIcon(sensitiveNodeUseCase: SensitiveNodeUseCaseProtocol,
                                       nodeIconUseCase: NodeIconUsecaseProtocol,
                                       accountUseCase: AccountUseCaseProtocol)
    }
    
    public static func makeThumbnailLoader(
        config: Configuration,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) -> any ThumbnailLoaderProtocol {
        
        switch config {
        case .general:
            makeThumbnailLoader(thumbnailUseCase: thumbnailUseCase)
        case .sensitive(let sensitiveNodeUseCase, let accountUseCase) where featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes):
            makeSensitiveThumbnailLoader(
                thumbnailUseCase: thumbnailUseCase,
                sensitiveNodeUseCase: sensitiveNodeUseCase,
                accountUseCase: accountUseCase
            )
        case .generalWithFallBackIcon(let nodeIconUseCase):
            makeThumbnailLoaderWithFallbackIcon(
                thumbnailUseCase: thumbnailUseCase,
                nodeIconUseCase: nodeIconUseCase
            )
        case .sensitiveWithFallbackIcon(let sensitiveNodeUseCase, let nodeIconUseCase, let accountUseCase):
            if featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) {
                makeSensitiveThumbnailLoaderWithFallbackIcon(
                    thumbnailUseCase: thumbnailUseCase,
                    sensitiveNodeUseCase: sensitiveNodeUseCase,
                    nodeIconUseCase: nodeIconUseCase,
                    accountUseCase: accountUseCase
                )
            } else {
                makeThumbnailLoaderWithFallbackIcon(
                    thumbnailUseCase: thumbnailUseCase,
                    nodeIconUseCase: nodeIconUseCase
                )
            }
        default:
            makeThumbnailLoader(thumbnailUseCase: thumbnailUseCase)
        }
    }
    
    private static func makeSensitiveThumbnailLoader(
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol
    ) -> some ThumbnailLoaderProtocol {
        SensitiveThumbnailLoader(
            thumbnailLoader: ThumbnailLoaderFactory.makeThumbnailLoader(thumbnailUseCase: thumbnailUseCase),
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            accountUseCase: accountUseCase)
    }
    
    private static func makeSensitiveThumbnailLoaderWithFallbackIcon(
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        nodeIconUseCase: some NodeIconUsecaseProtocol,
        accountUseCase: some AccountUseCaseProtocol
    ) -> some ThumbnailLoaderProtocol {
        SensitiveThumbnailLoader(
            thumbnailLoader: ThumbnailLoaderFactory.makeThumbnailLoaderWithFallbackIcon(thumbnailUseCase: thumbnailUseCase, nodeIconUseCase: nodeIconUseCase),
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            accountUseCase: accountUseCase)
    }
    
    private static func makeThumbnailLoader(thumbnailUseCase: some ThumbnailUseCaseProtocol) -> some ThumbnailLoaderProtocol {
        ThumbnailLoader(thumbnailUseCase: thumbnailUseCase)
    }
    
    private static func makeThumbnailLoaderWithFallbackIcon(thumbnailUseCase: some ThumbnailUseCaseProtocol, nodeIconUseCase: some NodeIconUsecaseProtocol) -> some ThumbnailLoaderProtocol {
        ThumbnailLoaderWithFallbackIcon(
            decoratee: ThumbnailLoader(thumbnailUseCase: thumbnailUseCase),
            nodeIconUseCase: nodeIconUseCase
        )
    }
}
