import MEGADomain
import MEGASwift

public final class MockUserVideoPlaylistsRepository: UserVideoPlaylistsRepositoryProtocol, @unchecked Sendable {
    
    public static var newRepo: MockUserVideoPlaylistsRepository {
        MockUserVideoPlaylistsRepository()
    }
    
    public enum Message: Sendable, Equatable {
        case userVideoPlaylists
        case addVideosToVideoPlaylist(id: HandleEntity, nodes: [NodeEntity])
        case deleteVideoPlaylistElements(videoPlaylistId: HandleEntity, elementIds: [HandleEntity])
        case deleteVideoPlaylist(id: HandleEntity)
        case videoPlaylistContent(id: HandleEntity, includeElementsInRubbishBin: Bool)
        case createVideoPlaylist(name: String?)
        case updateVideoPlaylistName(newName: String, videoPlaylistEntity: VideoPlaylistEntity)
    }
    
    public private(set) var messages = [Message]()
    
    public let setsUpdatedAsyncSequence: AnyAsyncSequence<[SetEntity]>
    public let setElementsUpdatedAsyncSequence: AnyAsyncSequence<[SetElementEntity]>
    private let videoPlaylistsResult: [SetEntity]
    private let addVideosToVideoPlaylistResult: Result<VideoPlaylistCreateSetElementsResultEntity, any Error>
    private let deleteVideosResult: Result<VideoPlaylistCreateSetElementsResultEntity, any Error>
    private let deleteVideoPlaylistResult: Result<VideoPlaylistEntity, any Error>
    private let videoPlaylistContentResult: [SetElementEntity]
    private let createVideoPlaylistResult: Result<SetEntity, any Error>
    private let updateVideoPlaylistNameResult: Result<Void, any Error>
    private let playlistContentUpdated: AnyAsyncSequence<[SetElementEntity]>
    
    public init(
        videoPlaylistsResult: [SetEntity] = [],
        addVideosToVideoPlaylistResult: Result<VideoPlaylistCreateSetElementsResultEntity, any Error> = .failure(GenericErrorEntity()),
        deleteVideosResult: Result<VideoPlaylistCreateSetElementsResultEntity, any Error> = .failure(GenericErrorEntity()),
        deleteVideoPlaylistResult: Result<VideoPlaylistEntity, any Error> = .failure(GenericErrorEntity()),
        videoPlaylistContentResult: [SetElementEntity] = [],
        createVideoPlaylistResult: Result<SetEntity, any Error> = .failure(GenericErrorEntity()),
        setsUpdatedAsyncSequence: AnyAsyncSequence<[SetEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        setElementsUpdatedAsyncSequence: AnyAsyncSequence<[SetElementEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        updateVideoPlaylistNameResult: Result<Void, any Error> = .failure(GenericErrorEntity()),
        playlistContentUpdated: AnyAsyncSequence<[SetElementEntity]> = EmptyAsyncSequence<[SetElementEntity]>().eraseToAnyAsyncSequence()

    ) {
        self.videoPlaylistsResult = videoPlaylistsResult
        self.addVideosToVideoPlaylistResult = addVideosToVideoPlaylistResult
        self.deleteVideosResult = deleteVideosResult
        self.deleteVideoPlaylistResult = deleteVideoPlaylistResult
        self.videoPlaylistContentResult = videoPlaylistContentResult
        self.createVideoPlaylistResult = createVideoPlaylistResult
        self.setsUpdatedAsyncSequence = setsUpdatedAsyncSequence
        self.setElementsUpdatedAsyncSequence = setElementsUpdatedAsyncSequence
        self.updateVideoPlaylistNameResult = updateVideoPlaylistNameResult
        self.playlistContentUpdated = playlistContentUpdated
    }
    
    public func videoPlaylists() async -> [SetEntity] {
        messages.append(.userVideoPlaylists)
        return videoPlaylistsResult
    }
    
    public func playlistContentUpdated(by id: HandleEntity) -> AnyAsyncSequence<[SetElementEntity]> {
        setElementsUpdatedAsyncSequence
            .compactMap { nodes in
                let filteredResult = nodes.filter { $0.ownerId == id }
                return filteredResult.isNotEmpty ? filteredResult : nil
            }
            .eraseToAnyAsyncSequence()
    }
    
    public func addVideosToVideoPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistCreateSetElementsResultEntity {
        messages.append(.addVideosToVideoPlaylist(id: id, nodes: nodes))
        return try addVideosToVideoPlaylistResult.get()
    }
    
    public func deleteVideoPlaylistElements(videoPlaylistId: HandleEntity, elementIds: [HandleEntity]) async throws -> VideoPlaylistCreateSetElementsResultEntity {
        messages.append(.deleteVideoPlaylistElements(videoPlaylistId: videoPlaylistId, elementIds: elementIds))
        return try deleteVideosResult.get()
    }
    
    public func deleteVideoPlaylist(by videoPlaylist: VideoPlaylistEntity) async throws -> VideoPlaylistEntity {
        messages.append(.deleteVideoPlaylist(id: videoPlaylist.id))
        return try deleteVideoPlaylistResult.get()
    }
    
    public func videoPlaylistContent(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> [SetElementEntity] {
        messages.append(.videoPlaylistContent(id: id, includeElementsInRubbishBin: includeElementsInRubbishBin))
        return videoPlaylistContentResult
    }
    
    public func createVideoPlaylist(_ name: String?) async throws -> SetEntity {
        messages.append(.createVideoPlaylist(name: name))
        return try createVideoPlaylistResult.get()
    }
    
    public func updateVideoPlaylistName(_ newName: String, for videoPlaylist: VideoPlaylistEntity) async throws {
        messages.append(.updateVideoPlaylistName(newName: newName, videoPlaylistEntity: videoPlaylist))
        return try updateVideoPlaylistNameResult.get()
    }
}
