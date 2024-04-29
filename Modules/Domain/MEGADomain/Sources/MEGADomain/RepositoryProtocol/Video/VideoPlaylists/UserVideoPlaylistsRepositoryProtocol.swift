public protocol UserVideoPlaylistsRepositoryProtocol: Sendable {
    
    /// Fetch all user video playlists
    /// - Returns: array of set entitites representing user video playlists
    func videoPlaylists() async -> [SetEntity]
    
    /// Add videos to the video playlist
    /// - Parameters:
    ///   - id: The video id
    ///   - nodes: The nodes need to be added to the video playlist
    /// - Returns: The CreateSetElementResultEntity
    ///   - success: means the number of videos added to the video playlist successfully
    ///   - failure: means the number of videos added to the video playlist unsuccessfully
    /// - throws: Throw `GenericErrorEntity` if it failed during adding videos to playlist
    func addVideosToVideoPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistCreateSetElementsResultEntity
    
    ///  Remove the video from the video playlist
    /// - Parameters:
    ///   - videoPlaylistId: The video playlist id
    ///   - elementIds: Elements needs to be deleted
    /// - Returns: The CreateSetElementResultEntity
    ///   - success: means the number of videos deleted from the video playlist successfully
    ///   - failure: means the number of videos deleted from the video playlist unsuccessfully
    func deleteVideoPlaylistElements(videoPlaylistId: HandleEntity, elementIds: [HandleEntity]) async throws -> VideoPlaylistCreateSetElementsResultEntity
    
    /// Fetch videos for a video playlist
    /// - Parameters:
    ///   - id: Video playlist id
    ///   - includeElementsInRubbishBin: a boolean flag to include or exclude fetching videos from rubbish bin
    /// - Returns: array of videos in form of `SetElementEntity`
    func videoPlaylistContent(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> [SetElementEntity]
}
