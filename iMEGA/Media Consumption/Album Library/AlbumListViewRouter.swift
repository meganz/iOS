import Combine
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import MEGASwiftUI
import SwiftUI

protocol AlbumListViewRouting {
    func cell(album: AlbumEntity, selectedAlbum: Binding<AlbumEntity?>, selection: AlbumSelection) -> AlbumCell
    func albumContainer(album: AlbumEntity, newAlbumPhotosToAdd: [NodeEntity]?, existingAlbumNames: @escaping () -> [String]) -> AlbumContainerWrapper
}

struct AlbumListViewRouter: AlbumListViewRouting, Routing {
    weak var photoAlbumContainerViewModel: PhotoAlbumContainerViewModel?
    
    @MainActor
    func cell(album: AlbumEntity, selectedAlbum: Binding<AlbumEntity?>, selection: AlbumSelection) -> AlbumCell {
        let nodeRepository = NodeRepository.newRepo
        let vm = AlbumCellViewModel(
            thumbnailLoader: ThumbnailLoaderFactory.makeThumbnailLoader(),
            monitorAlbumsUseCase: makeMonitorAlbumsUseCase(),
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo),
            sensitiveNodeUseCase: SensitiveNodeUseCase(nodeRepository: nodeRepository),
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo),
            albumCoverUseCase: AlbumCoverUseCase(nodeRepository: nodeRepository),
            album: album,
            selection: selection,
            selectedAlbum: selectedAlbum
        )
        return AlbumCell(viewModel: vm)
    }
    
    func albumContainer(album: AlbumEntity, newAlbumPhotosToAdd: [NodeEntity]?, existingAlbumNames: @escaping () -> [String]) -> AlbumContainerWrapper {
        return AlbumContainerWrapper(album: album, newAlbumPhotos: newAlbumPhotosToAdd, existingAlbumNames: existingAlbumNames)
    }
    
    @MainActor
    func build() -> UIViewController {
        let filesSearchRepo = FilesSearchRepository.newRepo
        let albumContentsUpdatesRepo = AlbumContentsUpdateNotifierRepository.newRepo
        let mediaUseCase = MediaUseCase(fileSearchRepo: filesSearchRepo)
        let userAlbumRepo = userAlbumRepository()
        let contentConsumptionUserAttributeUseCase = ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo)
        let photoLibraryUseCase = makePhotoLibraryUseCase()
        let hiddenNodesFeatureFlagEnabled = { @Sendable in DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) }
        
        let vm = AlbumListViewModel(
            usecase: AlbumListUseCase(
                photoLibraryUseCase: photoLibraryUseCase,
                mediaUseCase: mediaUseCase,
                userAlbumRepository: userAlbumRepo,
                albumContentsUpdateRepository: albumContentsUpdatesRepo,
                albumContentsUseCase: AlbumContentsUseCase(
                    albumContentsRepo: albumContentsUpdatesRepo,
                    mediaUseCase: mediaUseCase,
                    fileSearchRepo: filesSearchRepo,
                    userAlbumRepo: userAlbumRepo,
                    contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
                    photoLibraryUseCase: photoLibraryUseCase,
                    sensitiveNodeUseCase: SensitiveNodeUseCase(
                        nodeRepository: NodeRepository.newRepo),
                    hiddenNodesFeatureFlagEnabled: hiddenNodesFeatureFlagEnabled),
                contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
                hiddenNodesFeatureFlagEnabled: hiddenNodesFeatureFlagEnabled
            ),
            albumModificationUseCase: AlbumModificationUseCase(userAlbumRepo: userAlbumRepo),
            shareCollectionUseCase: ShareCollectionUseCase(
                shareAlbumRepository: ShareCollectionRepository.newRepo,
                userAlbumRepository: UserAlbumRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            ),
            tracker: DIContainer.tracker,
            monitorAlbumsUseCase: makeMonitorAlbumsUseCase(),
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
            alertViewModel: TextFieldAlertViewModel(title: Strings.Localizable.CameraUploads.Albums.Create.Alert.title,
                                                    placeholderText: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder,
                                                    affirmativeButtonTitle: Strings.Localizable.createFolderButton,
                                                    destructiveButtonTitle: Strings.Localizable.cancel,
                                                    message: nil),
            photoAlbumContainerViewModel: photoAlbumContainerViewModel
        )
        
        let content = AlbumListView(viewModel: vm,
                                    router: self)
        
        return UIHostingController(rootView: content)
    }
    
    func start() {}
    
    private func makeMonitorAlbumsUseCase() -> MonitorAlbumsUseCase {
        MonitorAlbumsUseCase(
            monitorPhotosUseCase: MonitorPhotosUseCase(
                photosRepository: PhotosRepository.sharedRepo,
                photoLibraryUseCase: makePhotoLibraryUseCase(),
                sensitiveNodeUseCase: SensitiveNodeUseCase(
                    nodeRepository: NodeRepository.newRepo)),
            mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
            userAlbumRepository: userAlbumRepository(),
            photosRepository: PhotosRepository.sharedRepo,
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo))
    }
    
    private func userAlbumRepository() -> any UserAlbumRepositoryProtocol {
        guard DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .albumPhotoCache) else {
            return UserAlbumRepository.newRepo
        }
        return UserAlbumCacheRepository.newRepo
    }
    
    private func makePhotoLibraryUseCase() -> some PhotoLibraryUseCaseProtocol {
        let photoLibraryRepository = PhotoLibraryRepository(
            cameraUploadNodeAccess: CameraUploadNodeAccess.shared)
        return PhotoLibraryUseCase(photosRepository: photoLibraryRepository,
                                   searchRepository: FilesSearchRepository.newRepo,
                                   contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
                                   hiddenNodesFeatureFlagEnabled: { DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) })
    }
}
