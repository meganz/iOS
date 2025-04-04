import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

extension ThumbnailLoaderFactory {
    public static func makeThumbnailLoader(
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase,
        mode: PhotoLibraryContentMode? = nil,
        configuration: ContentLibraries.Configuration = ContentLibraries.configuration
    ) -> any ThumbnailLoaderProtocol {
        if [PhotoLibraryContentMode.albumLink, .mediaDiscoveryFolderLink].notContains(mode) {
            makeThumbnailLoader(
                config: .sensitive(
                    sensitiveNodeUseCase: configuration.sensitiveNodeUseCase
                ),
                thumbnailUseCase: makeThumbnailUseCase(mode: mode),
                remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
        } else {
            makeThumbnailLoader(config: .general,
                                thumbnailUseCase: makeThumbnailUseCase(mode: mode),
                                remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
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
        let repository: ThumbnailRepository = switch mode {
        case .albumLink:
            .publicThumbnailRepository()
        case .mediaDiscoveryFolderLink:
            .folderLinkThumbnailRepository()
        default:
            .defaultThumbnailRepository()
        }
        
        return ThumbnailUseCase(repository: repository)
    }
}
