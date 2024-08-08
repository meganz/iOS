import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import SwiftUI

struct GetAlbumsLinksViewWrapper: UIViewControllerRepresentable {
    private let albums: [AlbumEntity]
    
    init(albums: [AlbumEntity]) {
        self.albums = albums
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let viewModel = makeViewModel(forAlbums: albums)
        return GetLinkViewController.instantiate(viewModel: viewModel)
    }
    
    private func makeViewModel(forAlbums albums: [AlbumEntity]) -> any GetLinkViewModelType {
        if albums.count == 1,
           let album = albums.first {
            makeGetAlbumLinkViewModel(album: album)
        } else {
            makeGetAlbumsLinkViewModel(albums: albums)
        }
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    // MARK: - Private
    
    private func makeGetAlbumLinkViewModel(album: AlbumEntity) -> GetAlbumLinkViewModel {
        let initialSections = ShareAlbumLinkInitialSections(
            album: album,
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
            monitorAlbumsUseCase: makeMonitorAlbumsUseCase(),
            contentConsumptionUserAttributeUseCase: makeContentConsumptionUserAttributeUseCase(),
            albumCoverUseCase: makeAlbumCoverUseCase())
        return GetAlbumLinkViewModel(
            album: album,
            shareAlbumUseCase: makeShareAlbumUseCase(),
            sectionViewModels: initialSections.initialLinkSectionViewModels,
            tracker: DIContainer.tracker)
    }
    
    private func makeGetAlbumsLinkViewModel(albums: [AlbumEntity]) -> GetAlbumsLinkViewModel {
        let initialSections = ShareAlbumsLinkInitialSections(
            albums: albums,
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
            monitorAlbumsUseCase: makeMonitorAlbumsUseCase(),
            contentConsumptionUserAttributeUseCase: makeContentConsumptionUserAttributeUseCase(),
            albumCoverUseCase: makeAlbumCoverUseCase())
        return GetAlbumsLinkViewModel(
            albums: albums,
            shareAlbumUseCase: makeShareAlbumUseCase(),
            sectionViewModels: initialSections.initialLinkSectionViewModels,
            tracker: DIContainer.tracker)
    }
    
    private func makeShareAlbumUseCase() -> some ShareAlbumUseCaseProtocol {
        ShareAlbumUseCase(
            shareAlbumRepository: ShareAlbumRepository.newRepo,
            userAlbumRepository: UserAlbumRepository.newRepo,
            nodeRepository: NodeRepository.newRepo)
    }
    
    private func makeMonitorAlbumsUseCase() -> some MonitorAlbumsUseCaseProtocol {
        MonitorAlbumsUseCase(
            monitorPhotosUseCase: MonitorPhotosUseCase(
                photosRepository: PhotosRepository.sharedRepo,
                photoLibraryUseCase: PhotoLibraryUseCase(
                    photosRepository: PhotoLibraryRepository(
                        cameraUploadNodeAccess: CameraUploadNodeAccess.shared),
                    searchRepository: FilesSearchRepository.newRepo,
                    contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
                    hiddenNodesFeatureFlagEnabled: { DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) }),
                sensitiveNodeUseCase: SensitiveNodeUseCase(
                    nodeRepository: NodeRepository.newRepo)),
            mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
            userAlbumRepository: UserAlbumCacheRepository.newRepo,
            photosRepository: PhotosRepository.sharedRepo,
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo)
        )
    }
    
    private func makeContentConsumptionUserAttributeUseCase() -> some ContentConsumptionUserAttributeUseCaseProtocol {
        ContentConsumptionUserAttributeUseCase(
            repo: UserAttributeRepository.newRepo)
    }
    
    private func makeAlbumCoverUseCase() -> some AlbumCoverUseCaseProtocol {
        AlbumCoverUseCase(
            nodeRepository: NodeRepository.newRepo)
    }
}
