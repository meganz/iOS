import MEGADomain

public final class MockRecentlyWatchedVideosRepository: RecentlyWatchedVideosRepositoryProtocol, @unchecked Sendable {
    
    public static var newRepo: MockRecentlyWatchedVideosRepository {
        MockRecentlyWatchedVideosRepository()
    }
    
    public enum Message: Equatable {
        case loadVideos
        case clearVideos
        case saveVideo(RecentlyWatchedVideoEntity)
    }
    
    public private(set) var messages: [Message] = []
    
    private let loadVideosResult: Result<[RecentlyWatchedVideoEntity], any Error>
    private let clearVideosResult: Result<Void, any Error>
    private let saveVideoResult: Result<Void, any Error>
    
    public init(
        loadVideosResult: Result<[RecentlyWatchedVideoEntity], any Error> = .failure(GenericErrorEntity()),
        clearVideosResult: Result<Void, any Error> = .failure(GenericErrorEntity()),
        saveVideoResult: Result<Void, any Error> = .failure(GenericErrorEntity())
    ) {
        self.loadVideosResult = loadVideosResult
        self.clearVideosResult = clearVideosResult
        self.saveVideoResult = saveVideoResult
    }
    
    public func loadVideos() async throws -> [RecentlyWatchedVideoEntity] {
        messages.append(.loadVideos)
        return try loadVideosResult.get()
    }
    
    public func clearVideos() throws {
        messages.append(.clearVideos)
        try clearVideosResult.get()
    }
    
    public func saveVideo(recentlyWatchedVideo: RecentlyWatchedVideoEntity) throws {
        messages.append(.saveVideo(recentlyWatchedVideo))
        try saveVideoResult.get()
    }
}
