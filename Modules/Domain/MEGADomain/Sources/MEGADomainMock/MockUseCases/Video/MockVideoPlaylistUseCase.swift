import Combine
import MEGADomain
import MEGASwift

public final class MockVideoPlaylistUseCase: VideoPlaylistUseCaseProtocol {
    
    public var videoPlaylistsUpdatedAsyncSequence: AnyAsyncSequence<Void> {
        EmptyAsyncSequence()
            .eraseToAnyAsyncSequence()
    }
    
    @Atomic public var messages = [Message]()
    @Published public var publishedMessage = [Message]()
    
    public enum Message: Equatable {
        case systemVideoPlaylists
        case userVideoPlaylists
    }
    
    private let systemVideoPlaylistsResult: [VideoPlaylistEntity]
    
    public init(systemVideoPlaylistsResult: [VideoPlaylistEntity] = []) {
        self.systemVideoPlaylistsResult = systemVideoPlaylistsResult
    }
    
    public func systemVideoPlaylists() async throws -> [VideoPlaylistEntity] {
        $messages.mutate { $0.append(.systemVideoPlaylists) }
        publishedMessage.append(.systemVideoPlaylists)
        return systemVideoPlaylistsResult
    }
    
    public func userVideoPlaylists() async -> [VideoPlaylistEntity] {
        $messages.mutate { $0.append(.userVideoPlaylists) }
        return []
    }
    
    public func createVideoPlaylist(_ name: String?) async throws -> VideoPlaylistEntity {
        throw GenericErrorEntity()
    }
}
