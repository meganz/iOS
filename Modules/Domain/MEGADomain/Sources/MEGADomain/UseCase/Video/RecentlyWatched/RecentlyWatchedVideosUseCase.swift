public protocol RecentlyWatchedVideosUseCaseProtocol: Sendable {
    func loadVideos() async throws -> [RecentlyWatchedVideoEntity]
    func clearVideos() throws
    func saveVideo(recentlyWatchedVideo: RecentlyWatchedVideoEntity) throws
}

public struct RecentlyWatchedVideosUseCase: RecentlyWatchedVideosUseCaseProtocol {
    
    private let recentlyWatchedVideosRepository: any RecentlyWatchedVideosRepositoryProtocol
    
    public init(recentlyWatchedVideosRepository: some RecentlyWatchedVideosRepositoryProtocol) {
        self.recentlyWatchedVideosRepository = recentlyWatchedVideosRepository
    }
    
    public func loadVideos() async throws -> [RecentlyWatchedVideoEntity] {
        try await recentlyWatchedVideosRepository.loadVideos()
    }
    
    public func clearVideos() throws {
        try recentlyWatchedVideosRepository.clearVideos()
    }
    
    public func saveVideo(recentlyWatchedVideo: RecentlyWatchedVideoEntity) throws {
        try recentlyWatchedVideosRepository.saveVideo(recentlyWatchedVideo: recentlyWatchedVideo)
    }
}
