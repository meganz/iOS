public protocol VideoPlaylistModificationUseCaseProtocol {
    func addVideoToPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistElementsResultEntity
    func deleteVideos(in videoPlaylistId: HandleEntity, videos: [VideoPlaylistVideoEntity]) async throws -> VideoPlaylistElementsResultEntity
}

public struct VideoPlaylistModificationUseCase: VideoPlaylistModificationUseCaseProtocol {
    
    private let userVideoPlaylistsRepository: any UserVideoPlaylistsRepositoryProtocol
    
    public init(userVideoPlaylistsRepository: some UserVideoPlaylistsRepositoryProtocol) {
        self.userVideoPlaylistsRepository = userVideoPlaylistsRepository
    }
    
    public func addVideoToPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistElementsResultEntity {
        let createSetElementsResultEntity = try await userVideoPlaylistsRepository.addVideosToVideoPlaylist(by: id, nodes: nodes)
        
        return VideoPlaylistElementsResultEntity(
            success: createSetElementsResultEntity.successCount,
            failure: createSetElementsResultEntity.errorCount
        )
    }
    
    public func deleteVideos(in videoPlaylistId: HandleEntity, videos: [VideoPlaylistVideoEntity]) async throws -> VideoPlaylistElementsResultEntity {
        let videoIds = videos.compactMap(\.videoPlaylistVideoId)
        guard videoIds.isNotEmpty else {
            return VideoPlaylistElementsResultEntity(success: 0, failure: 0)
        }
        let createSetElementsResultEntity = try await userVideoPlaylistsRepository.deleteVideoPlaylistElements(videoPlaylistId: videoPlaylistId, elementIds: videoIds)
        
        return VideoPlaylistElementsResultEntity(
            success: createSetElementsResultEntity.successCount,
            failure: createSetElementsResultEntity.errorCount
        )
    }
}
