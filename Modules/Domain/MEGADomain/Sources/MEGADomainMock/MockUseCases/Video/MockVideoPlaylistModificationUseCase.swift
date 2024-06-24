import MEGADomain
import MEGASwift

public final class MockVideoPlaylistModificationUseCase: VideoPlaylistModificationUseCaseProtocol {
    
    private let addToVideoPlaylistResult: Result<VideoPlaylistElementsResultEntity, any Error>
    private let deleteVideoPlaylistResult: [VideoPlaylistEntity]
    
    public enum Message: Equatable {
        case addVideoToPlaylist
        case deleteVideoPlaylist
    }
    
    public private(set) var messages = [Message]()
    
    public init(
        addToVideoPlaylistResult: Result<VideoPlaylistElementsResultEntity, any Error> = .failure(GenericErrorEntity()),
        deleteVideoPlaylistResult: [VideoPlaylistEntity] = []
    ) {
        self.addToVideoPlaylistResult = addToVideoPlaylistResult
        self.deleteVideoPlaylistResult = deleteVideoPlaylistResult
    }
    
    public func addVideoToPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistElementsResultEntity {
        messages.append(.addVideoToPlaylist)
        return try addToVideoPlaylistResult.get()
    }
    
    public func deleteVideos(in videoPlaylistId: HandleEntity, videos: [VideoPlaylistVideoEntity]) async throws -> VideoPlaylistElementsResultEntity {
        VideoPlaylistElementsResultEntity(success: 0, failure: 0)
    }
    
    public func delete(videoPlaylists: [VideoPlaylistEntity]) async -> [VideoPlaylistEntity] {
        messages.append(.deleteVideoPlaylist)
        return deleteVideoPlaylistResult
    }
}
