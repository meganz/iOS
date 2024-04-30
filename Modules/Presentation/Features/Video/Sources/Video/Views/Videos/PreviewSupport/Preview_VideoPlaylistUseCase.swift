import MEGADomain

struct Preview_VideoPlaylistUseCase: VideoPlaylistUseCaseProtocol {
    func systemVideoPlaylists() async throws -> [VideoPlaylistEntity] {
        []
    }
    
    func userVideoPlaylists() async -> [VideoPlaylistEntity] {
        []
    }
}
