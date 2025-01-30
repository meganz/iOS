import Combine
import MEGADomain
import MEGASwift

public final class MockVideoPlaylistModificationUseCase: VideoPlaylistModificationUseCaseProtocol, @unchecked Sendable {
    
    private let addToVideoPlaylistResult: Result<VideoPlaylistElementsResultEntity, any Error>
    private let deleteVideoPlaylistResult: [VideoPlaylistEntity]
    private let updateVideoPlaylistNameResult: Result<Void, any Error>
    private let deleteVideosInVideoPlaylistResult: Result<VideoPlaylistElementsResultEntity, any Error>
    private let invocationStream: AsyncStream<Invocation>
    private let invocationContinuation: AsyncStream<Invocation>.Continuation
    
    public enum Invocation: Equatable, Sendable {
        case addVideoToPlaylist(id: HandleEntity, nodes: [NodeEntity])
        case deleteVideoPlaylist
        case updateVideoPlaylistName
        case deleteVideosInVideoPlaylist
    }
    
    public private(set) var messages = [Invocation]()
    @Published public var invocations = [Invocation]()
    
    public var invocationSequence: AnyAsyncSequence<Invocation> {
        invocationStream.eraseToAnyAsyncSequence()
    }
    
    public init(
        addToVideoPlaylistResult: Result<VideoPlaylistElementsResultEntity, any Error> = .failure(GenericErrorEntity()),
        deleteVideoPlaylistResult: [VideoPlaylistEntity] = [],
        updateVideoPlaylistNameResult: Result<Void, any Error> = .failure(GenericErrorEntity()),
        deleteVideosInVideoPlaylistResult: Result<VideoPlaylistElementsResultEntity, any Error> = .failure(GenericErrorEntity())
    ) {
        self.addToVideoPlaylistResult = addToVideoPlaylistResult
        self.deleteVideoPlaylistResult = deleteVideoPlaylistResult
        self.updateVideoPlaylistNameResult = updateVideoPlaylistNameResult
        self.deleteVideosInVideoPlaylistResult = deleteVideosInVideoPlaylistResult
        (invocationStream, invocationContinuation) = AsyncStream.makeStream(of: Invocation.self)
    }
    
    public func addVideoToPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistElementsResultEntity {
        let invocation = Invocation.addVideoToPlaylist(id: id, nodes: nodes)
        messages.append(invocation)
        invocationContinuation.yield(invocation)
        return try addToVideoPlaylistResult.get()
    }
    
    public func deleteVideos(in videoPlaylistId: HandleEntity, videos: [VideoPlaylistVideoEntity]) async throws -> VideoPlaylistElementsResultEntity {
        messages.append(.deleteVideosInVideoPlaylist)
        invocations.append(.deleteVideosInVideoPlaylist)
        return try deleteVideosInVideoPlaylistResult.get()
    }
    
    public func delete(videoPlaylists: [VideoPlaylistEntity]) async -> [VideoPlaylistEntity] {
        messages.append(.deleteVideoPlaylist)
        return deleteVideoPlaylistResult
    }
    
    public func updateVideoPlaylistName(_ newName: String, for videoPlaylistEntity: VideoPlaylistEntity) async throws {
        messages.append(.updateVideoPlaylistName)
        return try updateVideoPlaylistNameResult.get()
    }
}
