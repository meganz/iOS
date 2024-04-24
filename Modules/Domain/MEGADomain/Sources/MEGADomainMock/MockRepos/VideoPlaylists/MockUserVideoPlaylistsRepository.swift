import MEGADomain

public actor MockUserVideoPlaylistsRepository: UserVideoPlaylistsRepositoryProtocol {
    
    public enum Message : Sendable, Equatable {
        case userVideoPlaylists
        case addVideosToVideoPlaylist(id: HandleEntity, nodes: [NodeEntity])
        case deleteVideoPlaylistElements(videoPlaylistId: HandleEntity, elementIds: [HandleEntity])
    }
    
    public private(set) var messages = [Message]()
    
    private let videoPlaylistsResult: [SetEntity]
    private let addVideosToVideoPlaylistResult: Result<VideoPlaylistCreateSetElementsResultEntity, Error>
    private let deleteVideosResult: Result<VideoPlaylistCreateSetElementsResultEntity, Error>
    
    public init(
        videoPlaylistsResult: [SetEntity],
        addVideosToVideoPlaylistResult: Result<VideoPlaylistCreateSetElementsResultEntity, Error>,
        deleteVideosResult: Result<VideoPlaylistCreateSetElementsResultEntity, Error>
    ) {
        self.videoPlaylistsResult = videoPlaylistsResult
        self.addVideosToVideoPlaylistResult = addVideosToVideoPlaylistResult
        self.deleteVideosResult = deleteVideosResult
    }
    
    public func videoPlaylists() async -> [SetEntity] {
        messages.append(.userVideoPlaylists)
        return videoPlaylistsResult
    }
    
    public func addVideosToVideoPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistCreateSetElementsResultEntity {
        messages.append(.addVideosToVideoPlaylist(id: id, nodes: nodes))
        return try addVideosToVideoPlaylistResult.get()
    }
    
    public func deleteVideoPlaylistElements(videoPlaylistId: HandleEntity, elementIds: [HandleEntity]) async throws -> VideoPlaylistCreateSetElementsResultEntity {
        messages.append(.deleteVideoPlaylistElements(videoPlaylistId: videoPlaylistId, elementIds: elementIds))
        return try deleteVideosResult.get()
    }
}
