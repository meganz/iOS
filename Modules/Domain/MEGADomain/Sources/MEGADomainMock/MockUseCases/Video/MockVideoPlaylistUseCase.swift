import MEGADomain
import MEGASwift

public final class MockVideoPlaylistUseCase: VideoPlaylistUseCaseProtocol {
    
    public var videoPlaylistsUpdatedAsyncSequence: AnyAsyncSequence<Void> {
        EmptyAsyncSequence()
            .eraseToAnyAsyncSequence()
    }
    
    @Atomic public var messages = [Message]()
    
    public enum Message: Equatable {
        case systemVideoPlaylists
        case userVideoPlaylists
    }
    
    public init() { }
    
    public func systemVideoPlaylists() async throws -> [VideoPlaylistEntity] {
        $messages.mutate { $0.append(.systemVideoPlaylists) }
        let systemVideoPlaylist = VideoPlaylistEntity(id: 1, name: "Favorites", count: 0, type: .favourite)
        return [systemVideoPlaylist]
    }
    
    public func userVideoPlaylists() async -> [VideoPlaylistEntity] {
        $messages.mutate { $0.append(.userVideoPlaylists) }
        return []
    }
}
