import MEGADomain
import MEGASwift

public final class MockVideoPlaylistContentUseCase: VideoPlaylistContentsUseCaseProtocol, @unchecked Sendable {
    
    private let allVideos: [NodeEntity]
    private let monitorVideoPlaylistAsyncSequenceResult: AnyAsyncThrowingSequence<VideoPlaylistEntity, any Error>
    private let monitorUserVideoPlaylistContentAsyncSequenceResult: AnyAsyncSequence<[NodeEntity]>
    
    public enum Message: Equatable {
        case monitorVideoPlaylist(id: HandleEntity)
    }
    
    public private(set) var messages = [Message]()
    
    public init(
        allVideos: [NodeEntity] = [],
        monitorVideoPlaylistAsyncSequenceResult: AnyAsyncThrowingSequence<VideoPlaylistEntity, any Error> = EmptyAsyncSequence().eraseToAnyAsyncThrowingSequence(),
        monitorUserVideoPlaylistContentAsyncSequenceResult: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.allVideos = allVideos
        self.monitorVideoPlaylistAsyncSequenceResult = monitorVideoPlaylistAsyncSequenceResult
        self.monitorUserVideoPlaylistContentAsyncSequenceResult = monitorUserVideoPlaylistContentAsyncSequenceResult
    }
    
    public func monitorVideoPlaylist(for videoPlaylist: VideoPlaylistEntity) -> AnyAsyncThrowingSequence<VideoPlaylistEntity, any Error> {
        messages.append(.monitorVideoPlaylist(id: videoPlaylist.id))
        return monitorVideoPlaylistAsyncSequenceResult
            .eraseToAnyAsyncThrowingSequence()
    }
    
    public func monitorUserVideoPlaylistContent(for videoPlaylist: VideoPlaylistEntity) -> AnyAsyncSequence<[NodeEntity]> {
        monitorUserVideoPlaylistContentAsyncSequenceResult
            .eraseToAnyAsyncSequence()
    }
    
    public func videos(in playlist: VideoPlaylistEntity) async throws -> [NodeEntity] {
        allVideos
    }
    
    public func userVideoPlaylistVideos(by id: HandleEntity) async -> [VideoPlaylistVideoEntity] {
        []
    }
}
