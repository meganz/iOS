import MEGADomain

public actor MockUserVideoPlaylistsRepository: UserVideoPlaylistsRepositoryProtocol {
    
    public enum Message : Sendable, Equatable {
        case userVideoPlaylists
        case addVideosToVideoPlaylist(id: HandleEntity, nodes: [NodeEntity])
    }
    
    public private(set) var messages = [Message]()
    
    private let videoPlaylistsResult: Result<[SetEntity], Error>
    private let addVideosToVideoPlaylistResult: Result<VideoPlaylistElementsResultEntity, Error>
    
    public init(
        videoPlaylistsResult: Result<[SetEntity], Error>,
        addVideosToVideoPlaylistResult: Result<VideoPlaylistElementsResultEntity, Error>
    ) {
        self.videoPlaylistsResult = videoPlaylistsResult
        self.addVideosToVideoPlaylistResult = addVideosToVideoPlaylistResult
    }
    
    public func videoPlaylists() async throws -> [SetEntity] {
        messages.append(.userVideoPlaylists)
        return try videoPlaylistsResult.get()
    }
    
    public func addVideosToVideoPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistElementsResultEntity {
        messages.append(.addVideosToVideoPlaylist(id: id, nodes: nodes))
        return try addVideosToVideoPlaylistResult.get()
    }
}
