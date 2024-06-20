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
        case createVideoPlaylist(name: String?)
        case updateVideoPlaylistName
    }
    
    private let systemVideoPlaylistsResult: [VideoPlaylistEntity]
    private let createVideoPlaylistResult: Result<VideoPlaylistEntity, any Error>
    private let updateVideoPlaylistNameResult: Result<Void, any Error>
    private let userVideoPlaylistsResult: [VideoPlaylistEntity]
    
    public init(
        systemVideoPlaylistsResult: [VideoPlaylistEntity] = [],
        createVideoPlaylistResult: Result<VideoPlaylistEntity, any Error> = .failure(GenericErrorEntity()),
        updateVideoPlaylistNameResult: Result<Void, any Error> = .failure(GenericErrorEntity()),
        userVideoPlaylistsResult: [VideoPlaylistEntity] = []
        
    ) {
        self.systemVideoPlaylistsResult = systemVideoPlaylistsResult
        self.createVideoPlaylistResult = createVideoPlaylistResult
        self.updateVideoPlaylistNameResult = updateVideoPlaylistNameResult
        self.userVideoPlaylistsResult = userVideoPlaylistsResult
    }
    
    public func systemVideoPlaylists() async throws -> [VideoPlaylistEntity] {
        $messages.mutate { $0.append(.systemVideoPlaylists) }
        publishedMessage.append(.systemVideoPlaylists)
        return systemVideoPlaylistsResult
    }
    
    public func userVideoPlaylists() async -> [VideoPlaylistEntity] {
        $messages.mutate { $0.append(.userVideoPlaylists) }
        return userVideoPlaylistsResult
    }
    
    public func createVideoPlaylist(_ name: String?) async throws -> VideoPlaylistEntity {
        $messages.mutate { $0.append(.createVideoPlaylist(name: name)) }
        return try createVideoPlaylistResult.get()
    }
    
    public func updateVideoPlaylistName(_ newName: String, for videoPlaylistEntity: VideoPlaylistEntity) async throws {
        $messages.mutate { $0.append(.updateVideoPlaylistName) }
        try updateVideoPlaylistNameResult.get()
    }
}
