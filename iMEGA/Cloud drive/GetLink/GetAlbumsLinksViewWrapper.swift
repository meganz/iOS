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
    
    @MainActor
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
    
    @MainActor
    private func makeGetAlbumLinkViewModel(album: AlbumEntity) -> GetAlbumLinkViewModel {
        let initialSections = ShareAlbumLinkInitialSections(
            album: album,
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
            monitorUserAlbumPhotosUseCase: makeMonitorUserAlbumPhotosUseCase(),
            sensitiveDisplayPreferenceUseCase: makeSensitiveDisplayPreferenceUseCase(),
            albumCoverUseCase: makeAlbumCoverUseCase())
        return GetAlbumLinkViewModel(
            album: album,
            shareCollectionUseCase: makeShareCollectionUseCase(),
            sectionViewModels: initialSections.initialLinkSectionViewModels,
            tracker: DIContainer.tracker)
    }
    
    @MainActor
    private func makeGetAlbumsLinkViewModel(albums: [AlbumEntity]) -> GetAlbumsLinkViewModel {
        let initialSections = ShareAlbumsLinkInitialSections(
            albums: albums,
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
            monitorUserAlbumPhotosUseCase: makeMonitorUserAlbumPhotosUseCase(),
            sensitiveDisplayPreferenceUseCase: makeSensitiveDisplayPreferenceUseCase(),
            albumCoverUseCase: makeAlbumCoverUseCase())
        return GetAlbumsLinkViewModel(
            albums: albums,
            shareCollectionUseCase: makeShareCollectionUseCase(),
            sectionViewModels: initialSections.initialLinkSectionViewModels,
            tracker: DIContainer.tracker)
    }
    
    private func makeShareCollectionUseCase() -> some ShareCollectionUseCaseProtocol {
        ShareCollectionUseCase(
            shareAlbumRepository: ShareCollectionRepository.newRepo,
            userAlbumRepository: UserAlbumRepository.newRepo,
            nodeRepository: NodeRepository.newRepo)
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
    
    private func makeSensitiveDisplayPreferenceUseCase() -> some SensitiveDisplayPreferenceUseCaseProtocol {
        SensitiveDisplayPreferenceUseCase(
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo),
            hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) })
    }
    
    private func makeAlbumCoverUseCase() -> some AlbumCoverUseCaseProtocol {
        AlbumCoverUseCase(
            nodeRepository: NodeRepository.newRepo)
    }
}
