import MEGADomain
import MEGASwift

public final class MockVideoPlaylistModificationUseCase: VideoPlaylistModificationUseCaseProtocol {
    
    private let addToVideoPlaylistResult: Result<VideoPlaylistElementsResultEntity, any Error>
    
    public enum Message: Equatable {
        case addVideoToPlaylist
    }
    
    public private(set) var messages = [Message]()
    
    public init(
        addToVideoPlaylistResult: Result<VideoPlaylistElementsResultEntity, any Error>
    ) {
        self.addToVideoPlaylistResult = addToVideoPlaylistResult
    }
    
    public func addVideoToPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistElementsResultEntity {
        messages.append(.addVideoToPlaylist)
        return try addToVideoPlaylistResult.get()
    }
    
    public func deleteVideos(in videoPlaylistId: HandleEntity, videos: [VideoPlaylistVideoEntity]) async throws -> VideoPlaylistElementsResultEntity {
        VideoPlaylistElementsResultEntity(success: 0, failure: 0)
    }
    
    public func delete(videoPlaylists: [VideoPlaylistEntity]) async -> [VideoPlaylistEntity] {
        []
    }
}
