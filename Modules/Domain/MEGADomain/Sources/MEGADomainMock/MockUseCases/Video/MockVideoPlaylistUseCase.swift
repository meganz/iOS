import MEGADomain

public final class MockVideoPlaylistUseCase: VideoPlaylistUseCaseProtocol {
    
    public private(set) var messages = [Message]()
    
    public enum Message: Equatable {
        case systemVideoPlaylists
        case userVideoPlaylists
    }
    
    public init() { }
    
    public func systemVideoPlaylists() async throws -> [VideoPlaylistEntity] {
        messages.append(.systemVideoPlaylists)
        let systemVideoPlaylist = VideoPlaylistEntity(id: 1, name: "Favorites", count: 0, type: .favourite)
        return [systemVideoPlaylist]
    }
    
    public func userVideoPlaylists() async -> [VideoPlaylistEntity] {
        messages.append(.userVideoPlaylists)
        return []
    }
}
