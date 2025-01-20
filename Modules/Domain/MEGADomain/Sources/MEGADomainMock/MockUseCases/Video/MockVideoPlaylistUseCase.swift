import Combine
import MEGADomain
import MEGASwift

public final class MockVideoPlaylistUseCase: VideoPlaylistUseCaseProtocol {
    
    public var videoPlaylistsUpdatedAsyncSequence: AnyAsyncSequence<Void> {
        _videoPlaylistsUpdatedAsyncSequence
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
    
    public var invocationSequence: AnyAsyncSequence<Invocation> {
        invocationStream.eraseToAnyAsyncSequence()
    }
    
    private let systemVideoPlaylistsResult: [VideoPlaylistEntity]
    private let createVideoPlaylistResult: Result<VideoPlaylistEntity, any Error>
    private let updateVideoPlaylistNameResult: Result<Void, any Error>
    private let userVideoPlaylistsResult: [VideoPlaylistEntity]
    private let _videoPlaylistsUpdatedAsyncSequence: AnyAsyncSequence<Void>
    private let invocationStream: AsyncStream<Invocation>
    private let invocationContinuation: AsyncStream<Invocation>.Continuation
    
    public init(
        systemVideoPlaylistsResult: [VideoPlaylistEntity] = [],
        createVideoPlaylistResult: Result<VideoPlaylistEntity, any Error> = .failure(GenericErrorEntity()),
        updateVideoPlaylistNameResult: Result<Void, any Error> = .failure(GenericErrorEntity()),
        userVideoPlaylistsResult: [VideoPlaylistEntity] = [],
        videoPlaylistsUpdatedAsyncSequence: AnyAsyncSequence<Void> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.systemVideoPlaylistsResult = systemVideoPlaylistsResult
        self.createVideoPlaylistResult = createVideoPlaylistResult
        self.updateVideoPlaylistNameResult = updateVideoPlaylistNameResult
        self.userVideoPlaylistsResult = userVideoPlaylistsResult
        _videoPlaylistsUpdatedAsyncSequence = videoPlaylistsUpdatedAsyncSequence
        (invocationStream, invocationContinuation) = AsyncStream.makeStream(of: Invocation.self)
    }
    
    public func systemVideoPlaylists() async throws -> [VideoPlaylistEntity] {
        await invocationsStore.append(.systemVideoPlaylists)
        invocationContinuation.yield(.systemVideoPlaylists)
        return systemVideoPlaylistsResult
    }
    
    public func userVideoPlaylists() async -> [VideoPlaylistEntity] {
        await invocationsStore.append(.userVideoPlaylists)
        invocationContinuation.yield(.userVideoPlaylists)
        return userVideoPlaylistsResult
    }
    
    public func createVideoPlaylist(_ name: String?) async throws -> VideoPlaylistEntity {
        await invocationsStore.append(.createVideoPlaylist(name: name))
        invocationContinuation.yield(.createVideoPlaylist(name: name))
        return try createVideoPlaylistResult.get()
    }
    
    public func updateVideoPlaylistName(_ newName: String, for videoPlaylistEntity: VideoPlaylistEntity) async throws {
        await invocationsStore.append(.updateVideoPlaylistName)
        invocationContinuation.yield(.updateVideoPlaylistName)
        try updateVideoPlaylistNameResult.get()
    }
}
