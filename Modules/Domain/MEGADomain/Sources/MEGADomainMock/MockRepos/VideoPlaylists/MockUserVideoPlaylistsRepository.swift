import MEGADomain

public actor MockUserVideoPlaylistsRepository: UserVideoPlaylistsRepositoryProtocol {
    
    public enum Message : Sendable, Equatable {
        case userVideoPlaylists
        case addVideosToVideoPlaylist(id: HandleEntity, nodes: [NodeEntity])
    }
    
    public private(set) var messages = [Message]()
    
    private let videoPlaylistsResult: [SetEntity]
    private let addVideosToVideoPlaylistResult: Result<VideoPlaylistCreateSetElementsResultEntity, Error>
    
    public init(
        videoPlaylistsResult: [SetEntity],
        addVideosToVideoPlaylistResult: Result<VideoPlaylistCreateSetElementsResultEntity, Error>
    ) {
        self.videoPlaylistsResult = videoPlaylistsResult
        self.addVideosToVideoPlaylistResult = addVideosToVideoPlaylistResult
    }
    
    public func videoPlaylists() async -> [SetEntity] {
        messages.append(.userVideoPlaylists)
        return videoPlaylistsResult
    }
    
    public func addVideosToVideoPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistCreateSetElementsResultEntity {
        messages.append(.addVideosToVideoPlaylist(id: id, nodes: nodes))
        return try addVideosToVideoPlaylistResult.get()
    }
}
