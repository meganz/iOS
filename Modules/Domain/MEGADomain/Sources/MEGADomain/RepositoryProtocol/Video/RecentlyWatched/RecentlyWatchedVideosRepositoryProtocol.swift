public protocol RecentlyWatchedVideosRepositoryProtocol: Sendable, RepositoryProtocol {
    
    /// Load recently watched videos represented as colletion of `RecentlyWatchedVideoEntity` object.
    /// - Returns: an array of `RecentlyWatchedVideoEntity`.
    func loadVideos() async throws -> [RecentlyWatchedVideoEntity]
    
    /// Clear all recently watched videos.
    ///  - Throws: Throws error if clear found error.
    func clearVideos() throws
    
    /// Save currently watched videos using `RecentlyWatchedVideoEntity` representation.
    /// - Parameter recentlyWatchedVideo: an object representing videos that is currently watched. The object contains the `video`, `lastWatchedDate`, and `lastWatchedTimestamp`.
    /// - Throws: throws error if failed to save video,
    func saveVideo(recentlyWatchedVideo: RecentlyWatchedVideoEntity) throws
}
