import ContentLibraries
import MEGADomain
import MEGAL10n
import MEGAPresentation
import SwiftUI

public final class AddToPlaylistViewModel: VideoPlaylistsContentViewModelProtocol {
    public let thumbnailLoader: any ThumbnailLoaderProtocol
    public let videoPlaylistContentUseCase: any VideoPlaylistContentsUseCaseProtocol
    public let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    public let router: any VideoRevampRouting
    private let videoPlaylistsUseCase: any VideoPlaylistUseCaseProtocol
    
    @Published var isVideoPlayListsLoaded = false
    @Published public var videoPlaylists = [VideoPlaylistEntity]()
    
    public init(
        thumbnailLoader: some ThumbnailLoaderProtocol,
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        router: some VideoRevampRouting,
        videoPlaylistsUseCase: any VideoPlaylistUseCaseProtocol
    ) {
        self.thumbnailLoader = thumbnailLoader
        self.videoPlaylistContentUseCase = videoPlaylistContentUseCase
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.router = router
        self.videoPlaylistsUseCase = videoPlaylistsUseCase
    }
    
    @MainActor
    func loadVideoPlaylists() async {
        videoPlaylists =  await videoPlaylistsUseCase.userVideoPlaylists()
            .sorted { $0.modificationTime < $1.modificationTime }
        
        guard !isVideoPlayListsLoaded else { return }
        isVideoPlayListsLoaded.toggle()
    }
}
