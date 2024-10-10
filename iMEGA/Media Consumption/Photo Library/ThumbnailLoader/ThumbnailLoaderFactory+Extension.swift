import Foundation
import MEGADomain
import MEGAPresentation
import MEGASDKRepo

extension ThumbnailLoaderFactory {
    static func makeThumbnailLoader(
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
         mode: PhotoLibraryContentMode? = nil
    ) -> any ThumbnailLoaderProtocol {
        if [PhotoLibraryContentMode.albumLink, .mediaDiscoveryFolderLink].notContains(mode) {
            makeThumbnailLoader(
                config: .sensitive(
                    sensitiveNodeUseCase: SensitiveNodeUseCase(
                        nodeRepository: NodeRepository.newRepo,
                        accountUseCase: AccountUseCase(
                            repository: AccountRepository.newRepo))),
                thumbnailUseCase: makeThumbnailUseCase(mode: mode),
                featureFlagProvider: featureFlagProvider)
        } else {
            makeThumbnailLoader(config: .general,
                                thumbnailUseCase: makeThumbnailUseCase(mode: mode),
                                featureFlagProvider: featureFlagProvider)
        }
    }
    
    private static func makeThumbnailUseCase(mode: PhotoLibraryContentMode? = nil) -> any ThumbnailUseCaseProtocol {
        if let mode {
            ThumbnailUseCase.makeThumbnailUseCase(mode: mode)
        } else {
            ThumbnailUseCase(repository: ThumbnailRepository.newRepo)
        }
    }
}

fileprivate extension ThumbnailUseCase where T == ThumbnailRepository {
    static func makeThumbnailUseCase(mode: PhotoLibraryContentMode) -> Self {
        let sdk: MEGASdk = switch mode {
        case .mediaDiscoveryFolderLink:
            .sharedFolderLink
        default:
            .shared
        }
        
        let provider: any MEGANodeProviderProtocol = switch mode {
        case .albumLink:
            PublicAlbumNodeProvider.shared
        default:
            DefaultMEGANodeProvider(sdk: sdk)
        }
        
        return ThumbnailUseCase(
            repository: ThumbnailRepository(
                sdk: sdk,
                fileManager: .default,
                nodeProvider: provider))
    }
}
