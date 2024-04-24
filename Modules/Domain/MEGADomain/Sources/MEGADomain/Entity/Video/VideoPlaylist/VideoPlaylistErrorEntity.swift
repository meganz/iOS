public enum VideoPlaylistErrorEntity: Error, Equatable {
    case invalidOperation
    case failedToAddVideoToPlaylist
    case failedToDeleteVideoPlaylistElements
    case failedToRetrieveSetFromRequest
}
