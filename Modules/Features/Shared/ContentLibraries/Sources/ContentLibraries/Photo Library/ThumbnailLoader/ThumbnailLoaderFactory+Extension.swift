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
        if [PhotoLibraryContentMode.albumLink, .mediaDiscoveryFolderLink, .mediaDiscoverySharedItems].notContains(mode) {
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
        guard let mode else {
            return ThumbnailUseCase(repository: ThumbnailRepository.newRepo)
        }
        return switch mode {
        case .albumLink:
            ThumbnailUseCase.makeAlbumLinkThumbnailUseCase()
        default:
            ThumbnailUseCase.makeThumbnailUseCase(mode: mode)
        }
    }
}

fileprivate extension ThumbnailUseCase where T == ThumbnailRepository {
    static func makeThumbnailUseCase(mode: PhotoLibraryContentMode) -> Self {
        let repository: ThumbnailRepository = switch mode {
        case .mediaDiscoveryFolderLink:
            .folderLinkThumbnailRepository()
        default:
            .defaultThumbnailRepository()
        }
        
        return ThumbnailUseCase(repository: repository)
    }
}

fileprivate extension ThumbnailUseCase where T == AlbumLinkThumbnailRepository {
    static func makeAlbumLinkThumbnailUseCase() -> Self {
        .init(repository: .albumLinkThumbnailRepository())
    }
}
