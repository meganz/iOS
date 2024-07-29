import MEGADomain
import MEGAL10n

/// Handles the fetching/mapping/filtering of content to be consumed in VideoPlaylistsViewModel.
/// This is used to separate concerns of breaching actor boundaries, when calling internal functions from different actors.
protocol VideoPlaylistsViewModelContentProviderProtocol: Sendable {
    
    /// Fetch all available playlists for this account, this includes System and User Playlists. And sort it according to the sort order
    /// - Parameter sortOrder: SortOrderEntity describing the order in which the playlists should be sorted
    /// - Returns: List of sorted VideoPlaylistEntities.
    func loadVideoPlaylists(sortOrder: SortOrderEntity) async -> [VideoPlaylistEntity]
}

struct VideoPlaylistsViewModelContentProvider: VideoPlaylistsViewModelContentProviderProtocol {
    
    private let videoPlaylistsUseCase: any VideoPlaylistUseCaseProtocol
    
    init(videoPlaylistsUseCase: some VideoPlaylistUseCaseProtocol) {
        self.videoPlaylistsUseCase = videoPlaylistsUseCase
    }
    
    func loadVideoPlaylists(sortOrder: SortOrderEntity) async -> [VideoPlaylistEntity] {
        
        async let systemVideoPlaylists = loadSystemVideoPlaylists()
        async let userVideoPlaylists = videoPlaylistsUseCase.userVideoPlaylists()
        
        let playlists = await systemVideoPlaylists + userVideoPlaylists
        return VideoPlaylistsSorter.sort(playlists, by: sortOrder)
    }

    private func loadSystemVideoPlaylists() async -> [VideoPlaylistEntity] {
        guard let playlists = try? await videoPlaylistsUseCase.systemVideoPlaylists() else {
            return []
        }
        return playlists.map { videoPlaylist -> VideoPlaylistEntity in
            VideoPlaylistEntity(
                id: videoPlaylist.id,
                name: Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Title.favorites,
                count: videoPlaylist.count,
                type: videoPlaylist.type,
                creationTime: videoPlaylist.creationTime,
                modificationTime: videoPlaylist.modificationTime
            )
        }
    }
}
