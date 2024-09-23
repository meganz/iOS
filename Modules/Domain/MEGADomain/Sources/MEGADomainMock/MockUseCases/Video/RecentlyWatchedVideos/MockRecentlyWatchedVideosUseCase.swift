import MEGADomain
import MEGASwift

public final class MockRecentlyWatchedVideosUseCase: RecentlyWatchedVideosUseCaseProtocol, @unchecked Sendable {
    
    public enum Invocation: Sendable, Equatable {
        case loadVideos
        case clearVideos
        case saveVideo
    }
    
    @Atomic public var invocations = [Invocation]()
    
    private let loadVideosResult: Result<[RecentlyWatchedVideoEntity], any Error>
    
    public init(
        loadVideosResult: Result<[RecentlyWatchedVideoEntity], any Error> = .failure(GenericErrorEntity())
    ) {
        self.loadVideosResult = loadVideosResult
    }
    
    public func loadVideos() async throws -> [RecentlyWatchedVideoEntity] {
        $invocations.mutate { $0.append(.loadVideos) }
        return try loadVideosResult.get()
    }
    
    public func clearVideos() throws {
        $invocations.mutate { $0.append(.clearVideos) }
    }
    
    public func saveVideo(recentlyWatchedVideo: RecentlyWatchedVideoEntity) throws {
        $invocations.mutate { $0.append(.saveVideo) }
        throw GenericErrorEntity()
    }
}
