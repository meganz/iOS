import MEGADomain
import MEGAL10n

/// Handles the fetching/mapping/filtering of content to be consumed in VideoPlaylistsViewModel.
/// This is used to separate concerns of breaching actor boundaries, when calling internal functions from different actors.
protocol VideoPlaylistsViewModelContentProviderProtocol: Sendable {
    
    /// Clear and invalidate any content and state, so that the next request for content will reload from source.
    func invalidateContent() async
    
    /// Fetch all available playlists for this account, this includes System and User Playlists. And sort it according to the sort order
    /// - Parameter searchText: Search text to filter the loaded playlists by there name.
    /// - Parameter sortOrder: SortOrderEntity describing the order in which the playlists should be sorted
    /// - Returns: List of sorted VideoPlaylistEntities.
    func loadVideoPlaylists(searchText: String, sortOrder: SortOrderEntity) async throws -> [VideoPlaylistEntity]
}

actor VideoPlaylistsViewModelContentProvider: VideoPlaylistsViewModelContentProviderProtocol {
    
    private var playlistsContainer: LoadedVideoPlaylistsContainer = .empty
    private var latestRequest: VideoPlaylistLoadingRequest? {
        willSet { latestRequest?.cancel() }
    }
    private let videoPlaylistsUseCase: any VideoPlaylistUseCaseProtocol
    
    init(videoPlaylistsUseCase: some VideoPlaylistUseCaseProtocol) {
        self.videoPlaylistsUseCase = videoPlaylistsUseCase
    }
    
    func invalidateContent() async {
        latestRequest = nil
        playlistsContainer = .empty
    }
    
    func loadVideoPlaylists(searchText: String, sortOrder: SortOrderEntity) async throws -> [VideoPlaylistEntity] {
        
        // If there is an existing request, with same criteria return the task
        if let latestRequest,
           latestRequest.isCancelled() == false,
           latestRequest.isDuplicate(of: searchText, sortOrder: sortOrder) {
            return try await latestRequest.playlists()
        }
        
        let request: VideoPlaylistLoadingRequest = .init(
            searchString: searchText,
            sortOrder: sortOrder,
            task: Task {
                
                let modified = if playlistsContainer.shouldReload(for: sortOrder) {
                    try await loadVideoPlaylists(sortOrder: sortOrder)
                } else {
                    playlistsContainer.playlists
                }
                
                try Task.checkCancellation()
                
                self.playlistsContainer = .init(playlists: modified, sortOrder: sortOrder)
                
                return if searchText.isNotEmpty {
                    filter(playlists: modified, searchText: searchText)
                } else {
                    modified
                }
            })
        
        latestRequest = request
        
        return try await request.playlists()
    }
    
    private func loadVideoPlaylists(sortOrder: SortOrderEntity) async throws -> [VideoPlaylistEntity] {
        
        let systemVideoPlaylists = try await loadSystemVideoPlaylists()
        let userVideoPlaylists = await videoPlaylistsUseCase.userVideoPlaylists()
        
        try Task.checkCancellation()
        
        return systemVideoPlaylists + VideoPlaylistsSorter.sort(userVideoPlaylists, by: sortOrder)
    }
    
    private func filter(playlists: [VideoPlaylistEntity], searchText: String) -> [VideoPlaylistEntity] {
        playlists.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private func loadSystemVideoPlaylists() async throws -> [VideoPlaylistEntity] {
        guard let playlists = try? await videoPlaylistsUseCase.systemVideoPlaylists() else {
            return []
        }
        
        try Task.checkCancellation()
        
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

private struct VideoPlaylistLoadingRequest {
    private let searchString: String
    private let sortOrder: SortOrderEntity
    private let task: Task<[VideoPlaylistEntity], any Error>
    
    init(searchString: String, sortOrder: SortOrderEntity, task: Task<[VideoPlaylistEntity], any Error>) {
        self.searchString = searchString
        self.sortOrder = sortOrder
        self.task = task
    }
    
    func cancel() {
        task.cancel()
    }
    
    func isCancelled() -> Bool {
        task.isCancelled
    }
    
    func playlists() async throws -> [VideoPlaylistEntity] {
        try Task.checkCancellation()
        return try await task.value
    }
    
    func isDuplicate(of searchText: String, sortOrder: SortOrderEntity) -> Bool {
        [
            self.searchString == searchText,
            self.sortOrder == sortOrder
        ].allSatisfy { $0 }
    }
}

private struct LoadedVideoPlaylistsContainer {
    
    static var empty: Self { .init(playlists: [], sortOrder: .defaultAsc) }
    
    let playlists: [VideoPlaylistEntity]
    let sortOrder: SortOrderEntity
    
    func shouldReload(for sortOrder: SortOrderEntity) -> Bool {
        playlists.isEmpty || self.sortOrder != sortOrder
    }
}
