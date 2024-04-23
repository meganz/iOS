import Combine

final class VideoPlaylistsViewModel: ObservableObject {
    @Published var shouldShowAddNewPlaylistAlert = false
    @Published var playlistName = ""
    
    init(syncModel: VideoRevampSyncModel) {
        syncModel.$shouldShowAddNewPlaylistAlert.assign(to: &$shouldShowAddNewPlaylistAlert)
    }
}
