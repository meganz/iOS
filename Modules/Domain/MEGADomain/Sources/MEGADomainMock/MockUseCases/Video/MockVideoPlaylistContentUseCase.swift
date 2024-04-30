import MEGADomain

public final class MockVideoPlaylistContentUseCase: VideoPlaylistContentsUseCaseProtocol {
    
    private let allVideos: [NodeEntity]
    
    public init(allVideos: [NodeEntity] = []) {
        self.allVideos = allVideos
    }
    
    public func videos(in playlist: VideoPlaylistEntity) async throws -> [NodeEntity] {
        allVideos
    }
    
    public func userVideoPlaylistVideos(by id: HandleEntity) async -> [VideoPlaylistVideoEntity] {
        []
    }
}
