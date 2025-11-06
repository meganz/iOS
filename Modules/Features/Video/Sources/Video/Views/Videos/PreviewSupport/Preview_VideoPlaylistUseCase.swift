import Foundation
import MEGADomain
import MEGASwift

struct Preview_VideoPlaylistUseCase: VideoPlaylistUseCaseProtocol {
    let userVideoPlaylists: [VideoPlaylistEntity]
    
    init(userVideoPlaylists: [VideoPlaylistEntity] = []) {
        self.userVideoPlaylists = userVideoPlaylists
    }
    
    var videoPlaylistsUpdatedAsyncSequence: AnyAsyncSequence<Void> {
        EmptyAsyncSequence()
            .eraseToAnyAsyncSequence()
    }
    
    func systemVideoPlaylists() async throws -> [VideoPlaylistEntity] {
        []
    }
    
    func userVideoPlaylists() async -> [VideoPlaylistEntity] {
        userVideoPlaylists
    }
    
    func createVideoPlaylist(_ name: String?) async throws -> VideoPlaylistEntity {
        VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "Preview", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
    }
    
    func updateVideoPlaylistName(_ newName: String, for videoPlaylistEntity: VideoPlaylistEntity) async throws { }
}
