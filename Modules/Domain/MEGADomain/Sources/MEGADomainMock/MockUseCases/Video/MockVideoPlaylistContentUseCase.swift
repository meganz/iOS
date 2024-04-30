import MEGADomain

public final class MockVideoPlaylistContentUseCase: VideoPlaylistContentsUseCaseProtocol {
    
    public init() { }
    
    public func videos(in playlist: VideoPlaylistEntity) async throws -> [NodeEntity] {
        []
    }
    
    public func userVideoPlaylistVideos(by id: HandleEntity) async -> [VideoPlaylistVideoEntity] {
        []
    }
}
