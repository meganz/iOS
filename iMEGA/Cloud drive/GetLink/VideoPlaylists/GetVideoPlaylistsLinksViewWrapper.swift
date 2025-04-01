import MEGAAppPresentation
import MEGADomain
import MEGASDKRepo
import SwiftUI

struct GetVideoPlaylistsLinksViewWrapper: UIViewControllerRepresentable {
    private let videoPlaylist: VideoPlaylistEntity
    
    init(videoPlaylist: VideoPlaylistEntity) {
        self.videoPlaylist = videoPlaylist
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let viewModel = makeGetVideoPlaylistLinkViewModel(videoPlaylist: videoPlaylist)
        return GetLinkViewController.instantiate(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    // MARK: - Private
    
    @MainActor
    private func makeGetVideoPlaylistLinkViewModel(videoPlaylist: VideoPlaylistEntity) -> GetCollectionLinkViewModel {
        let initialSections = ShareVideoPlaylistLinkInitialSections(
            videoPlaylist: videoPlaylist,
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo)
        )
        return GetCollectionLinkViewModel(
            setEntity: videoPlaylist.toSetEntity(currentUserHandle: currentUserHandle()),
            shareCollectionUseCase: makeShareCollectionUseCase(),
            sectionViewModels: initialSections.initialLinkSectionViewModels,
            tracker: DIContainer.tracker
        )
    }
    
    private func currentUserHandle() -> HandleEntity {
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        return accountUseCase.currentUserHandle ?? .invalid
    }
    
    private func makeShareCollectionUseCase() -> some ShareCollectionUseCaseProtocol {
        ShareCollectionUseCase(
            shareAlbumRepository: ShareCollectionRepository.newRepo,
            userAlbumRepository: UserAlbumRepository.newRepo,
            nodeRepository: NodeRepository.newRepo)
    }
}
