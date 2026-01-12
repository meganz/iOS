import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPhotos
import MEGARepo
import UIKit

@MainActor
enum VisualMediaSearchFactory {
    static func makeVisualMediaSearchResultsViewModel(
        presenter: UIViewController?,
    ) -> VisualMediaSearchResultsViewModel {
        .init(
            photoAlbumContainerInteractionManager: .init(),
            visualMediaSearchHistoryUseCase: Self.makeVisualMediaSearchHistoryUseCase(),
            monitorAlbumsUseCase: Self.makeMonitorAlbumsUseCase(),
            thumbnailLoader: ThumbnailLoaderFactory.makeThumbnailLoader(),
            monitorUserAlbumPhotosUseCase: Self.makeMonitorUserAlbumPhotosUseCase(),
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            ),
            sensitiveNodeUseCase: Self.makeSensitiveNodeUseCase(),
            sensitiveDisplayPreferenceUseCase: Self.makeSensitiveDisplayPreferenceUseCase(),
            albumCoverUseCase: AlbumCoverUseCase(
                nodeRepository: NodeRepository.newRepo),
            monitorPhotosUseCase: Self.makeMonitorPhotosUseCase(),
            photoSearchResultRouter: Self.makePhotoSearchResultRouter(
                presenter: presenter))
    }
    
    private static func makeVisualMediaSearchHistoryUseCase() -> some VisualMediaSearchHistoryUseCaseProtocol {
        VisualMediaSearchHistoryUseCase(
            visualMediaSearchHistoryRepository: VisualMediaSearchHistoryCacheRepository.sharedRepo)
    }
    
    private static func makeMonitorAlbumsUseCase() -> some MonitorAlbumsUseCaseProtocol {
        let sensitiveNodeUseCase = SensitiveNodeUseCase(
            nodeRepository: NodeRepository.newRepo,
            accountUseCase: AccountUseCase(
                repository: AccountRepository.newRepo))
        
        return MonitorAlbumsUseCase(
            monitorPhotosUseCase: MonitorPhotosUseCase(
                photosRepository: PhotosRepository.sharedRepo,
                photoLibraryUseCase: makePhotoLibraryUseCase(),
                sensitiveNodeUseCase: sensitiveNodeUseCase),
            mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
            userAlbumRepository: UserAlbumRepository.newRepo,
            photosRepository: PhotosRepository.sharedRepo,
            sensitiveNodeUseCase: sensitiveNodeUseCase)
    }
    
    private static func makePhotoLibraryUseCase() -> some PhotoLibraryUseCaseProtocol {
        let photoLibraryRepository = PhotoLibraryRepository(
            cameraUploadNodeAccess: CameraUploadNodeAccess.shared)
        return PhotoLibraryUseCase(
            photosRepository: photoLibraryRepository,
            searchRepository: FilesSearchRepository.newRepo,
            sensitiveDisplayPreferenceUseCase: makeSensitiveDisplayPreferenceUseCase(),
            hiddenNodesFeatureFlagEnabled: {
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes)
            }
        )
    }
    
    private static func makeSensitiveDisplayPreferenceUseCase() -> some SensitiveDisplayPreferenceUseCaseProtocol {
        SensitiveDisplayPreferenceUseCase(
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo),
            hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) })
    }
    
    private static func makeMonitorUserAlbumPhotosUseCase() -> some MonitorUserAlbumPhotosUseCaseProtocol {
        MonitorUserAlbumPhotosUseCase(
            userAlbumRepository: UserAlbumCacheRepository.newRepo,
            photosRepository: PhotosRepository.sharedRepo,
            sensitiveNodeUseCase: makeSensitiveNodeUseCase()
        )
    }
    
    private static func makeMonitorPhotosUseCase() -> some MonitorPhotosUseCaseProtocol {
        MonitorPhotosUseCase(
            photosRepository: PhotosRepository.sharedRepo,
            photoLibraryUseCase: makePhotoLibraryUseCase(),
            sensitiveNodeUseCase: makeSensitiveNodeUseCase())
    }
    
    private static func makeSensitiveNodeUseCase() -> some SensitiveNodeUseCaseProtocol {
        SensitiveNodeUseCase(
            nodeRepository: NodeRepository.newRepo,
            accountUseCase: AccountUseCase(
                repository: AccountRepository.newRepo)
        )
    }
    
    private static func makePhotoSearchResultRouter(
        presenter: UIViewController?,
    ) -> some PhotoSearchResultRouterProtocol {
        PhotoSearchResultRouter(
            presenter: presenter,
            nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate(
                viewController: presenter ?? UIViewController(),
                moveToRubbishBinViewModel: MoveToRubbishBinViewModel(
                    presenter: presenter ?? UIViewController())
            ),
            backupsUseCase: BackupsUseCase(
                backupsRepository: BackupsRepository.newRepo,
                nodeRepository: NodeRepository.newRepo)
        )
    }
}
