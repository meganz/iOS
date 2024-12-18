import MEGADomain
import MEGAPhotos
import MEGAPresentation
import MEGASDKRepo
import MEGASwiftUI
import SwiftUI

public struct AddToCollectionRouter: AddToCollectionRouting {
    private weak var presenter: UIViewController?
    private let mode: AddToMode
    private let selectedPhotos: [NodeEntity]
    
    public init(
        presenter: UIViewController?,
        mode: AddToMode,
        selectedPhotos: [NodeEntity]
    ) {
        self.presenter = presenter
        self.mode = mode
        self.selectedPhotos = selectedPhotos
    }
    
    public func build() -> UIViewController {
        let nodeRepository = NodeRepository.newRepo
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        let sensitiveNodeUseCase = SensitiveNodeUseCase(
            nodeRepository: nodeRepository,
            accountUseCase: accountUseCase)
        let sensitiveDisplayPreferenceUseCase = SensitiveDisplayPreferenceUseCase(
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo),
            hiddenNodesFeatureFlagEnabled: {
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) }
        )
        let albumContentsUpdatesRepo = AlbumContentsUpdateNotifierRepository.newRepo
        let photoLibraryUseCase = makePhotoLibraryUseCase()
        let mediaUseCase = MediaUseCase(
            fileSearchRepo: FilesSearchRepository.newRepo)
        let userAlbumRepo = UserAlbumCacheRepository.newRepo
        
        let content = AddToCollectionView(viewModel: .init(
            mode: mode,
            selectedPhotos: selectedPhotos,
            addToAlbumsViewModel: .init(
                monitorAlbumsUseCase: makeMonitorAlbumsUseCase(),
                thumbnailLoader: ThumbnailLoaderFactory.makeThumbnailLoader(),
                monitorUserAlbumPhotosUseCase: makeMonitorUserAlbumPhotosUseCase(),
                nodeUseCase: NodeUseCase(
                    nodeDataRepository: NodeDataRepository.newRepo,
                    nodeValidationRepository: NodeValidationRepository.newRepo,
                    nodeRepository: nodeRepository
                ),
                sensitiveNodeUseCase: sensitiveNodeUseCase,
                sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
                albumCoverUseCase: AlbumCoverUseCase(nodeRepository: nodeRepository),
                albumListUseCase: AlbumListUseCase(
                    photoLibraryUseCase: photoLibraryUseCase,
                    mediaUseCase: mediaUseCase,
                    userAlbumRepository: userAlbumRepo,
                    albumContentsUpdateRepository: albumContentsUpdatesRepo,
                    albumContentsUseCase: AlbumContentsUseCase(
                        albumContentsRepo: albumContentsUpdatesRepo,
                        mediaUseCase: mediaUseCase,
                        fileSearchRepo: FilesSearchRepository.newRepo,
                        userAlbumRepo: userAlbumRepo,
                        sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
                        photoLibraryUseCase: photoLibraryUseCase,
                        sensitiveNodeUseCase: sensitiveNodeUseCase
                    ),
                    sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase
                ),
                albumModificationUseCase: AlbumModificationUseCase(userAlbumRepo: userAlbumRepo),
                addToCollectionRouter: self
            )
        ))
        return UIHostingController(rootView: content)
    }
    
    public func start() {
        presenter?.present(build(),
                           animated: true)
    }
    
    public func showSnackBar(message: String) {
        UIApplication.mnz_visibleViewController()
            .showSnackBar(snackBar: SnackBar(message: message))
    }
    
    private func makeSensitiveDisplayPreferenceUseCase() -> some SensitiveDisplayPreferenceUseCaseProtocol {
        SensitiveDisplayPreferenceUseCase(
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo),
            hiddenNodesFeatureFlagEnabled: {
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) })
    }
    
    private func makeMonitorAlbumsUseCase() -> MonitorAlbumsUseCase {
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
            userAlbumRepository: UserAlbumCacheRepository.newRepo,
            photosRepository: PhotosRepository.sharedRepo,
            sensitiveNodeUseCase: sensitiveNodeUseCase)
    }
    
    private func makeMonitorUserAlbumPhotosUseCase() -> some MonitorUserAlbumPhotosUseCaseProtocol {
        MonitorUserAlbumPhotosUseCase(
            userAlbumRepository: UserAlbumCacheRepository.newRepo,
            photosRepository: PhotosRepository.sharedRepo,
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(
                    repository: AccountRepository.newRepo))
        )
    }
    
    private func makePhotoLibraryUseCase() -> some PhotoLibraryUseCaseProtocol {
        let photoLibraryRepository = PhotoLibraryRepository(
            cameraUploadNodeAccess: CameraUploadNodeAccess.shared)
        return PhotoLibraryUseCase(
            photosRepository: photoLibraryRepository,
            searchRepository: FilesSearchRepository.newRepo,
            sensitiveDisplayPreferenceUseCase: makeSensitiveDisplayPreferenceUseCase(),
            hiddenNodesFeatureFlagEnabled: {
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) })
    }
}
