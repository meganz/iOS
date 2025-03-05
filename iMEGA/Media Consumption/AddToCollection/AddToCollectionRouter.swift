import MEGADomain
import MEGAPhotos
import MEGAPresentation
import MEGASDKRepo
import MEGASwiftUI
import SwiftUI

public final class AddToCollectionRouter: AddToCollectionRouting {
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
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
        let fileSearchRepo = FilesSearchRepository.newRepo
        let userVideoPlaylistRepository = UserVideoPlaylistsRepository.newRepo
        
        let content = AddToCollectionView(viewModel: .init(
            mode: self.mode,
            selectedPhotos: self.selectedPhotos,
            addToAlbumsViewModel: .init(
                monitorAlbumsUseCase: self.makeMonitorAlbumsUseCase(),
                thumbnailLoader: ThumbnailLoaderFactory.makeThumbnailLoader(),
                monitorUserAlbumPhotosUseCase: self.makeMonitorUserAlbumPhotosUseCase(),
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
                        fileSearchRepo: fileSearchRepo,
                        userAlbumRepo: userAlbumRepo,
                        sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
                        photoLibraryUseCase: photoLibraryUseCase,
                        sensitiveNodeUseCase: sensitiveNodeUseCase
                    ),
                    sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase
                ),
                albumModificationUseCase: AlbumModificationUseCase(userAlbumRepo: userAlbumRepo),
                addToCollectionRouter: self
            ),
            addToPlaylistViewModel: .init(
                thumbnailLoader: ThumbnailLoaderFactory.makeThumbnailLoader(),
                videoPlaylistContentUseCase: VideoPlaylistContentsUseCase(
                    userVideoPlaylistRepository: userVideoPlaylistRepository,
                    photoLibraryUseCase: photoLibraryUseCase,
                    fileSearchRepository: fileSearchRepo,
                    nodeRepository: nodeRepository,
                    sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
                    sensitiveNodeUseCase: sensitiveNodeUseCase
                ),
                sortOrderPreferenceUseCase: SortOrderPreferenceUseCase(
                    preferenceUseCase: PreferenceUseCase.default,
                    sortOrderPreferenceRepository: SortOrderPreferenceRepository.newRepo
                ),
                router: VideoRevampRouter(
                    explorerType: .video,
                    navigationController: self.presenter?.navigationController),
                videoPlaylistsUseCase: VideoPlaylistUseCase(
                    fileSearchUseCase: FilesSearchUseCase(
                        repo: fileSearchRepo,
                        nodeRepository: nodeRepository),
                    userVideoPlaylistsRepository: userVideoPlaylistRepository,
                    photoLibraryUseCase: photoLibraryUseCase),
                videoPlaylistModificationUseCase: VideoPlaylistModificationUseCase(
                    userVideoPlaylistsRepository: userVideoPlaylistRepository),
                addToCollectionRouter: self
            )
        ))
        let hostingController = UIHostingController(rootView: content)
        baseViewController = hostingController
        return hostingController
    }
    
    public func start() {
        guard !showOverDiskQuotaIfNeeded() else { return }
        presenter?.present(build(), animated: true)
    }
    
    public func dismiss(completion: (() -> Void)?) {
        baseViewController?.dismiss(animated: true, completion: completion)
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
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes)
            },
            searchByNodeTagsFeatureFlagEnabled: {
                DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .searchByNodeTags)
            }
        )
    }
    
    private func showOverDiskQuotaIfNeeded() -> Bool {
        OverDiskQuotaChecker(
            accountStorageUseCase: AccountStorageUseCase(
                accountRepository: AccountRepository.newRepo,
                preferenceUseCase: PreferenceUseCase.default
            ),
            appDelegateRouter: AppDelegateRouter())
        .showOverDiskQuotaIfNeeded()
    }
}
