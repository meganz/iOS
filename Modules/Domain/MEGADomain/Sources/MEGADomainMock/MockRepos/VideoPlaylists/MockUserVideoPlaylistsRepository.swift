import MEGADomain

public actor MockUserVideoPlaylistsRepository: UserVideoPlaylistsRepositoryProtocol {
    
    public enum Message: Sendable, Equatable {
        case userVideoPlaylists
        case addVideosToVideoPlaylist(id: HandleEntity, nodes: [NodeEntity])
        case deleteVideoPlaylistElements(videoPlaylistId: HandleEntity, elementIds: [HandleEntity])
        case videoPlaylistContent(id: HandleEntity, includeElementsInRubbishBin: Bool)
    }
    
    public private(set) var messages = [Message]()
    
    private let videoPlaylistsResult: [SetEntity]
    private let addVideosToVideoPlaylistResult: Result<VideoPlaylistCreateSetElementsResultEntity, Error>
    private let deleteVideosResult: Result<VideoPlaylistCreateSetElementsResultEntity, Error>
    private let videoPlaylistContentResult: [SetElementEntity]
    
    public init(
        videoPlaylistsResult: [SetEntity] = [],
        addVideosToVideoPlaylistResult: Result<VideoPlaylistCreateSetElementsResultEntity, Error> = .failure(GenericErrorEntity()),
        deleteVideosResult: Result<VideoPlaylistCreateSetElementsResultEntity, Error> = .failure(GenericErrorEntity()),
        videoPlaylistContentResult: [SetElementEntity] = []
    ) {
        self.videoPlaylistsResult = videoPlaylistsResult
        self.addVideosToVideoPlaylistResult = addVideosToVideoPlaylistResult
        self.deleteVideosResult = deleteVideosResult
        self.videoPlaylistContentResult = videoPlaylistContentResult
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
    
    public func videoPlaylistContent(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> [SetElementEntity] {
        messages.append(.videoPlaylistContent(id: id, includeElementsInRubbishBin: includeElementsInRubbishBin))
        return videoPlaylistContentResult
    }
}
