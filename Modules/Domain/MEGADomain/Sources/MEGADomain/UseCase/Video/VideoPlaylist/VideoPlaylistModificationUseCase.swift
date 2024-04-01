public protocol VideoPlaylistModificationUseCaseProtocol {
    func addVideoToPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistElementsResultEntity
}

public struct VideoPlaylistModificationUseCase: VideoPlaylistModificationUseCaseProtocol {
    
    private let userVideoPlaylistsRepository: any UserVideoPlaylistsRepositoryProtocol
    
    public init(userVideoPlaylistsRepository: some UserVideoPlaylistsRepositoryProtocol) {
        self.userVideoPlaylistsRepository = userVideoPlaylistsRepository
    }
    
    public func addVideoToPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistElementsResultEntity {
        try await userVideoPlaylistsRepository.addVideosToVideoPlaylist(by: id, nodes: nodes)
    }
}
