import MEGADomain

public final class Preview_VideoPlaylistModificationUseCase: VideoPlaylistModificationUseCaseProtocol {
    
    public func addVideoToPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistElementsResultEntity {
        VideoPlaylistElementsResultEntity(success: 0, failure: 0)
    }
    
    public func deleteVideos(in videoPlaylistId: HandleEntity, videos: [VideoPlaylistVideoEntity]) async throws -> VideoPlaylistElementsResultEntity {
        VideoPlaylistElementsResultEntity(success: 0, failure: 0)
    }
    
    public func delete(videoPlaylists: [VideoPlaylistEntity]) async -> [VideoPlaylistEntity] {
        []
    }
    
    public func updateVideoPlaylistName(_ newName: String, for videoPlaylistEntity: VideoPlaylistEntity) async throws {
        
    }
}
