public protocol UserVideoPlaylistsRepositoryProtocol: Sendable {
    
    /// Fetch all user video playlists
    /// - Returns: array of set entitites representing user video playlists
    func videoPlaylists() async throws -> [SetEntity]
    
    /// Add videos to the video playlist
    /// - Parameters:
    ///   - id: The video id
    ///   - nodes: The nodes need to be added to the video playlist
    /// - Returns: The CreateSetElementResultEntity
    ///   - success: means the number of videos added to the video playlist successfully
    ///   - failure: means the number of videos added to the video playlist unsuccessfully
    /// - throws: Throw `GenericErrorEntity` if it failed during adding videos to playlist
    func addVideosToVideoPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistElementsResultEntity
}
