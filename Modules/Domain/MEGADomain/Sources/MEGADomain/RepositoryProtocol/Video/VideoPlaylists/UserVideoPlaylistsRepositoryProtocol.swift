import MEGASwift

public protocol UserVideoPlaylistsRepositoryProtocol: Sendable, RepositoryProtocol {
    
    /// Listen to video playlist set update changes.
    /// - Returns: an AsyncSequence that emits video playlist updates.
    var setsUpdatedAsyncSequence: AnyAsyncSequence<[SetEntity]> { get }
    
    /// Listen to video playlist content  set element updates.
    /// - Returns: An AnyAsyncSequence that emits video playlist content updates.
    var setElementsUpdatedAsyncSequence: AnyAsyncSequence<[SetElementEntity]> { get }
    
    /// Fetch all user video playlists
    /// - Returns: array of set entitites representing user video playlists
    func videoPlaylists() async -> [SetEntity]
    
    /// AnyAsyncSequence that produces the SetElementEntity list when a change has occurred on the specific user playlist.
    /// - Parameter id: The user playlist id
    /// - Returns: AnyAsyncSequence<[SetElementEntity]> of all the changed elements. Only yields when a new update has occurred.
    func playlistContentUpdated(by id: HandleEntity) -> AnyAsyncSequence<[SetElementEntity]>
    
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
    
    /// Remove the user video playlist
    /// - Parameter videoPlaylist: The user video playlist to remove
    /// - Returns: The  removed user video playlist
    func deleteVideoPlaylist(by videoPlaylist: VideoPlaylistEntity) async throws -> VideoPlaylistEntity
    
    /// Fetch videos for a video playlist
    /// - Parameters:
    ///   - id: Video playlist id
    ///   - includeElementsInRubbishBin: a boolean flag to include or exclude fetching videos from rubbish bin
    /// - Returns: array of videos in form of `SetElementEntity`
    func videoPlaylistContent(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> [SetElementEntity]
    
    /// Create user video playlist with specific name
    /// - Parameter name: Name of the playlist that will be created.
    /// - Returns: `SetEntity` instance representing created video playlist.
    /// - throws: Throw `VideoPlaylistErrorEntity` if it failed during adding videos to playlist or `CancellationError` if cancelled.
    func createVideoPlaylist(_ name: String?) async throws -> SetEntity
    
    /// Rename specific video playlist
    /// - Parameters:
    ///   - newName: new name for the target video playlist.
    ///   - videoPlaylist: `VideoPlaylistEntity` instance that wants to be renamed.
    /// - Throws: `VideoPlaylistErrorEntity` if failed to update video playlist name.
    func updateVideoPlaylistName(_ newName: String, for videoPlaylist: VideoPlaylistEntity) async throws
}
