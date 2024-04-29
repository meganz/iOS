import MEGASwift

public protocol VideoPlaylistContentsUseCaseProtocol: Sendable {
    
    /// Fetch videos from a specific `VideoPlaylistEntity` instance
    /// - Parameter playlist: instance of `VideoPlaylistEntity` to fetch videos from
    /// - Returns: nodes of videos
    func videos(in playlist: VideoPlaylistEntity) async throws -> [NodeEntity]
    
    /// Fetch videos of a video playlist by its id
    /// - Parameter id: id of the video playlist
    /// - Returns: array of `VideoPlaylistVideoEntity` instances
    func userVideoPlaylistVideos(by id: HandleEntity) async -> [VideoPlaylistVideoEntity]
}

public struct VideoPlaylistContentsUseCase: VideoPlaylistContentsUseCaseProtocol {
    
    private let userVideoPlaylistRepository: any UserVideoPlaylistsRepositoryProtocol
    private let photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    private let fileSearchRepository: any FilesSearchRepositoryProtocol
    
    public init(
        userVideoPlaylistRepository: some UserVideoPlaylistsRepositoryProtocol,
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol,
        fileSearchRepository: some FilesSearchRepositoryProtocol
    ) {
        self.userVideoPlaylistRepository = userVideoPlaylistRepository
        self.photoLibraryUseCase = photoLibraryUseCase
        self.fileSearchRepository = fileSearchRepository
    }
    
    // MARK: - videos
    
    public func videos(in playlist: VideoPlaylistEntity) async throws -> [NodeEntity] {
        switch playlist.type {
        case .favourite:
            try await photoLibraryUseCase.media(for: [.videos, .cloudDrive], excludeSensitive: nil)
                .filter(\.isFavourite)
        default:
            await userVideoPlaylistVideos(by: playlist.id).map(\.video)
        }
    }
    
    // MARK: - userVideoPlaylistVideos
    
    public func userVideoPlaylistVideos(by id: HandleEntity) async -> [VideoPlaylistVideoEntity] {
        await withTaskGroup(of: VideoPlaylistVideoEntity?.self) { group in
            let videoSetElements = await userVideoPlaylistRepository.videoPlaylistContent(
                by: id,
                includeElementsInRubbishBin: false
            )
            
            for setElement in videoSetElements {
                group.addTask {
                    await video(from: setElement)
                }
            }
            
            return await group.reduce(into: [VideoPlaylistVideoEntity]()) { result, video in
                if let video = video {
                    result.append(video)
                }
            }
        }
    }
    
    private func video(from setElement: SetElementEntity) async -> VideoPlaylistVideoEntity? {
        guard let video = await fetchVideo(id: setElement.nodeId) else {
            return nil
        }
        return VideoPlaylistVideoEntity(video: video, videoPlaylistVideoId: setElement.id)
    }
    
    private func fetchVideo(id nodeId: HandleEntity) async -> NodeEntity? {
        guard
            let video = await fileSearchRepository.node(by: nodeId),
            video.name.fileExtensionGroup.isVideo
        else {
            return nil
        }
        return video
    }
}
