import Combine
import MEGADomain
import MEGASwift

public final class MockVideoPlaylistUseCase: VideoPlaylistUseCaseProtocol {
    
    public var videoPlaylistsUpdatedAsyncSequence: AnyAsyncSequence<Void> {
        EmptyAsyncSequence()
            .eraseToAnyAsyncSequence()
    }
    
    public actor InvocationsStore {
        @Published public var invocations = [Invocation]()
        
        func append(_ invocation: Invocation) {
            invocations.append(invocation)
        }
    }
    public let invocationsStore = InvocationsStore()
    
    public enum Invocation: Equatable, Sendable {
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
        await invocationsStore.append(.systemVideoPlaylists)
        return systemVideoPlaylistsResult
    }
    
    public func userVideoPlaylists() async -> [VideoPlaylistEntity] {
        await invocationsStore.append(.userVideoPlaylists)
        return userVideoPlaylistsResult
    }
    
    public func createVideoPlaylist(_ name: String?) async throws -> VideoPlaylistEntity {
        await invocationsStore.append(.createVideoPlaylist(name: name))

        return try createVideoPlaylistResult.get()
    }
    
    public func updateVideoPlaylistName(_ newName: String, for videoPlaylistEntity: VideoPlaylistEntity) async throws {
        await invocationsStore.append(.updateVideoPlaylistName)
        try updateVideoPlaylistNameResult.get()
    }
}
