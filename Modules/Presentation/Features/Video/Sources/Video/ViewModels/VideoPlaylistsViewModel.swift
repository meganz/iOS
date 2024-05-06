import Combine
import MEGADomain
import MEGAL10n

final class VideoPlaylistsViewModel: ObservableObject {
    private let videoPlaylistsUseCase: any VideoPlaylistUseCaseProtocol
    private(set) var thumbnailUseCase: any ThumbnailUseCaseProtocol
    private(set) var videoPlaylistContentUseCase: any VideoPlaylistContentsUseCaseProtocol
    
    @Published var videoPlaylists = [VideoPlaylistEntity]()
    @Published var shouldShowAddNewPlaylistAlert = false
    @Published var playlistName = ""
    
    init(
        videoPlaylistsUseCase: some VideoPlaylistUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        videoPlaylistContentUseCase: some VideoPlaylistContentsUseCaseProtocol,
        syncModel: VideoRevampSyncModel
    ) {
        self.videoPlaylistsUseCase = videoPlaylistsUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.videoPlaylistContentUseCase = videoPlaylistContentUseCase
        syncModel.$shouldShowAddNewPlaylistAlert.assign(to: &$shouldShowAddNewPlaylistAlert)
    }
    
    @MainActor
    func onViewAppeared() async {
        async let systemVideoPlaylists = loadSystemVideoPlaylists()
        async let userVideoPlaylists = videoPlaylistsUseCase.userVideoPlaylists()
        
        videoPlaylists = await systemVideoPlaylists + userVideoPlaylists
    }
    
    private func loadSystemVideoPlaylists() async -> [VideoPlaylistEntity] {
        guard let videoPlaylist = try? await videoPlaylistsUseCase.systemVideoPlaylists() else {
            return []
        }
        
        return videoPlaylist
            .compactMap { videoPlaylist in
                guard videoPlaylist.isSystemVideoPlaylist else {
                    return nil
                }
                return VideoPlaylistEntity(
                    id: videoPlaylist.id,
                    name: Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Title.favorites,
                    count: videoPlaylist.count,
                    type: videoPlaylist.type
                )
            }
    }
}
