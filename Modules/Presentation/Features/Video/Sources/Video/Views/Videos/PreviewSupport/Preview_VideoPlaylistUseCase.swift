import MEGADomain
import MEGASwift

struct Preview_VideoPlaylistUseCase: VideoPlaylistUseCaseProtocol {
    
    var videoPlaylistsUpdatedAsyncSequence: AnyAsyncSequence<Void> {
        EmptyAsyncSequence()
            .eraseToAnyAsyncSequence()
    }
    
    func systemVideoPlaylists() async throws -> [VideoPlaylistEntity] {
        []
    }
    
    func userVideoPlaylists() async -> [VideoPlaylistEntity] {
        []
    }
    
    func createVideoPlaylist(_ name: String?) async throws -> VideoPlaylistEntity {
        VideoPlaylistEntity(id: 1, name: "Preview", count: 0, type: .user)
    }
}
