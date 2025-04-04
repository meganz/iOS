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
        case sensitive(sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol)
        
        /// Configuration used to create a General Purpose ThumbnailLoader with fallback icon if failed to generate the icon
        /// This variation will generate URLImageContainers and ImageContainers
        case generalWithFallBackIcon(nodeIconUseCase: any NodeIconUsecaseProtocol)
        
        /// Configuration used to create a SensitiveThumbnailLoader with fallback icon if failed to generate the icon
        /// This variation will generate variations adhering to SensitiveImageContaining and ImageContainers
        case sensitiveWithFallbackIcon(sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol,
                                       nodeIconUseCase: any NodeIconUsecaseProtocol)
    }
    
    public static func makeThumbnailLoader(
        config: Configuration,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase
    ) -> any ThumbnailLoaderProtocol {
        
        switch config {
        case .general:
            makeThumbnailLoader(thumbnailUseCase: thumbnailUseCase)
        case .sensitive(let sensitiveNodeUseCase) where remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes):
            makeSensitiveThumbnailLoader(
                thumbnailUseCase: thumbnailUseCase,
                sensitiveNodeUseCase: sensitiveNodeUseCase
            )
        case .generalWithFallBackIcon(let nodeIconUseCase):
            makeThumbnailLoaderWithFallbackIcon(
                thumbnailUseCase: thumbnailUseCase,
                nodeIconUseCase: nodeIconUseCase
            )
        case .sensitiveWithFallbackIcon(let sensitiveNodeUseCase, let nodeIconUseCase):
            if remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) {
                makeSensitiveThumbnailLoaderWithFallbackIcon(
                    thumbnailUseCase: thumbnailUseCase,
                    sensitiveNodeUseCase: sensitiveNodeUseCase,
                    nodeIconUseCase: nodeIconUseCase
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
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol
    ) -> some ThumbnailLoaderProtocol {
        SensitiveThumbnailLoader(
            thumbnailLoader: ThumbnailLoaderFactory.makeThumbnailLoader(thumbnailUseCase: thumbnailUseCase),
            sensitiveNodeUseCase: sensitiveNodeUseCase)
    }
    
    private static func makeSensitiveThumbnailLoaderWithFallbackIcon(
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        nodeIconUseCase: some NodeIconUsecaseProtocol
    ) -> some ThumbnailLoaderProtocol {
        SensitiveThumbnailLoader(
            thumbnailLoader: ThumbnailLoaderFactory.makeThumbnailLoaderWithFallbackIcon(thumbnailUseCase: thumbnailUseCase, nodeIconUseCase: nodeIconUseCase),
            sensitiveNodeUseCase: sensitiveNodeUseCase)
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
