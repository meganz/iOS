import Foundation
import MEGADomain
import MEGASwift

public final class Preview_VideoPlaylistContentUseCase: VideoPlaylistContentsUseCaseProtocol {
    
    public func monitorVideoPlaylist(for videoPlaylist: VideoPlaylistEntity) -> AnyAsyncThrowingSequence<VideoPlaylistEntity, any Error> {
        EmptyAsyncSequence().eraseToAnyAsyncThrowingSequence()
    }
    
    public func monitorUserVideoPlaylistContent(for videoPlaylist: VideoPlaylistEntity) -> AnyAsyncSequence<[NodeEntity]> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    public func monitorUserVideoPlaylist(for videoPlaylist: MEGADomain.VideoPlaylistEntity) -> MEGASwift.AnyAsyncThrowingSequence<MEGADomain.VideoPlaylistEntity, any Error> {
        EmptyAsyncSequence()
            .eraseToAnyAsyncThrowingSequence()
    }
    
    public init() { }
    
    public func monitorFavoriteVideoPlaylist() -> AnyAsyncSequence<[NodeEntity]> {
        EmptyAsyncSequence()
            .eraseToAnyAsyncSequence()
    }
    
    public func monitorUserVideoPlaylist(for videoPlaylist: VideoPlaylistEntity) -> AnyAsyncSequence<[VideoPlaylistEntity]> {
        EmptyAsyncSequence()
            .eraseToAnyAsyncSequence()
    }
    
    public func videos(in playlist: VideoPlaylistEntity) async throws -> [NodeEntity] {
        []
    }
    
    public func userVideoPlaylistVideos(by id: HandleEntity) async -> [VideoPlaylistVideoEntity] {
        []
    }
}
