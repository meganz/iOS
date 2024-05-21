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
}
