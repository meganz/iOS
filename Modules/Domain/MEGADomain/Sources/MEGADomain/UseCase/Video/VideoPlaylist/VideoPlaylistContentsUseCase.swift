import AsyncAlgorithms
import MEGASwift

public protocol VideoPlaylistContentsUseCaseProtocol: Sendable {
    
    /// An async throwing sequence of VideoPlaylistEntity can throw error that  will emit updated given VideoPlaylistEntity values.
    /// - Parameter videoPlaylist: VideoPlaylistEntity instance that wants to be monitored
    /// - Returns: Stream of either Updated `VideoPlaylistEntity` or `Error` (CancellationError if cancelled, VideoPlaylistErrorEntity if other error)`.
    func monitorVideoPlaylist(for videoPlaylist: VideoPlaylistEntity) -> AnyAsyncThrowingSequence<VideoPlaylistEntity, any Error>
    
    /// An async sequence of collection of `NodeEntity` can throw error that  will emit updated given VideoPlaylistEntity values.
    /// - Parameter videoPlaylist: VideoPlaylistEntity instance which its content wants to be monitored
    /// - Returns: Stream of either Updated video node entities
    func monitorUserVideoPlaylistContent(for videoPlaylist: VideoPlaylistEntity) -> AnyAsyncSequence<[NodeEntity]>
    
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
    private let nodeRepository: any NodeRepositoryProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let hiddenNodesFeatureFlagEnabled: @Sendable () -> Bool

    public init(
        userVideoPlaylistRepository: some UserVideoPlaylistsRepositoryProtocol,
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol,
        fileSearchRepository: some FilesSearchRepositoryProtocol,
        nodeRepository: some NodeRepositoryProtocol,
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        hiddenNodesFeatureFlagEnabled: @escaping @Sendable () -> Bool
    ) {
        self.userVideoPlaylistRepository = userVideoPlaylistRepository
        self.photoLibraryUseCase = photoLibraryUseCase
        self.fileSearchRepository = fileSearchRepository
        self.nodeRepository = nodeRepository
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.hiddenNodesFeatureFlagEnabled = hiddenNodesFeatureFlagEnabled
    }
    
    // MARK: - monitorVideoPlaylist
    
    public func monitorVideoPlaylist(for videoPlaylist: VideoPlaylistEntity) -> AnyAsyncThrowingSequence<VideoPlaylistEntity, any Error> {
        switch videoPlaylist.type {
        case .favourite:
            monitorFavoriteVideoPlaylist(for: videoPlaylist)
        case .user:
            monitorUserVideoPlaylist(for: videoPlaylist)
        }
    }
    
    private func monitorFavoriteVideoPlaylist(for videoPlaylist: VideoPlaylistEntity) -> AnyAsyncThrowingSequence<VideoPlaylistEntity, any Error> {
        SingleItemAsyncSequence(item: videoPlaylist)
            .eraseToAnyAsyncThrowingSequence()
    }
    
    private func monitorUserVideoPlaylist(for videoPlaylist: VideoPlaylistEntity) -> AnyAsyncThrowingSequence<VideoPlaylistEntity, any Error> {
        userVideoPlaylistRepository.setsUpdatedAsyncSequence
            .compactMap {
                $0.first(where: { $0.handle == videoPlaylist.id && $0.setType == .playlist })
            }
            .compactMap { setEntity in
                switch setEntity.changeTypes {
                case .name:
                    return setEntity.toVideoPlaylistEntity(type: .user, sharedLinkStatus: .exported(setEntity.isExported))
                case .removed:
                    throw VideoPlaylistErrorEntity.videoPlaylistNotFound(id: videoPlaylist.id)
                default:
                    return nil
                }
            }
            .prepend {
                try await self.videoPlaylist(by: videoPlaylist.id)
            }
            .eraseToAnyAsyncThrowingSequence()
    }
    
    // MARK: - monitorUserVideoPlaylistContent
    public func monitorUserVideoPlaylistContent(for videoPlaylist: VideoPlaylistEntity) -> AnyAsyncSequence<[NodeEntity]> {
        switch videoPlaylist.type {
        case .favourite:
            // NOTE: There is a hang here, this will be addressed in CC-7904
            merge(
                updatedVideoNodes().map { _ in () },
                sensitiveNodeUseCase.folderSensitivityChanged())
            .compactMap { _ in
                try? await videos(in: videoPlaylist)
            }
            .prepend {
                (try? await videos(in: videoPlaylist)) ?? []
            }
            .eraseToAnyAsyncSequence()
        case .user:
            merge(contentUpdated(in: videoPlaylist),
                  nodesUpdated(in: videoPlaylist),
                  playlistVideosOnFolderSensitivityChanged(in: videoPlaylist))
                .prepend {
                    (try? await videos(in: videoPlaylist)) ?? []
                }
                .eraseToAnyAsyncSequence()
        }
    }
    
    // MARK: - videos
    
    public func videos(in playlist: VideoPlaylistEntity) async throws -> [NodeEntity] {
        
        let excludeSensitive = await shouldExcludeSensitive()
        
        return switch playlist.type {
        case .favourite:
            try await photoLibraryUseCase.media(
                for: [.allLocations, .videos],
                excludeSensitive: excludeSensitive)
            .filter(\.isFavourite)
        default:
            await userVideoPlaylistVideos(by: playlist.id, excludeSensitive: excludeSensitive)
                .map(\.video)
        }
    }
    
    // MARK: - userVideoPlaylistVideos
    
    public func userVideoPlaylistVideos(by id: HandleEntity) async -> [VideoPlaylistVideoEntity] {
        let excludeSensitive = await shouldExcludeSensitive()

        return await userVideoPlaylistVideos(by: id, excludeSensitive: excludeSensitive)
    }
    
    private func userVideoPlaylistVideos(by id: HandleEntity, excludeSensitive: Bool) async -> [VideoPlaylistVideoEntity] {
        await withTaskGroup(of: VideoPlaylistVideoEntity?.self) { group in
            let videoSetElements = await userVideoPlaylistRepository.videoPlaylistContent(
                by: id,
                includeElementsInRubbishBin: false
            )
            
            for setElement in videoSetElements {
                group.addTask {
                    await video(from: setElement, excludeSensitive: excludeSensitive)
                }
            }
            
            return await group.reduce(into: [VideoPlaylistVideoEntity]()) { result, video in
                if let video = video {
                    result.append(video)
                }
            }
        }
    }
    
    private func shouldExcludeSensitive() async -> Bool {
        guard hiddenNodesFeatureFlagEnabled() else {
            return false
        }
        
        return await !contentConsumptionUserAttributeUseCase.fetchSensitiveAttribute().showHiddenNodes
    }
    
    private func video(from setElement: SetElementEntity, excludeSensitive: Bool) async -> VideoPlaylistVideoEntity? {
        guard 
            let video = await fetchVideo(id: setElement.nodeId) else {
            return nil
        }
        
        let isNodeAllowed = if !excludeSensitive {
            true
        } else if video.isMarkedSensitive {
            false
        } else {
            !(await isInheritingSensitivity(node: video))
        }
        
        guard isNodeAllowed else {
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
    
    private func videoPlaylist(by id: HandleEntity) async throws -> VideoPlaylistEntity {
        guard let videoPlaylist = await userVideoPlaylistRepository.videoPlaylists().first(where: { $0.handle == id }) else {
            throw VideoPlaylistErrorEntity.videoPlaylistNotFound(id: id)
        }
        
        return videoPlaylist.toVideoPlaylistEntity(type: .user, sharedLinkStatus: .exported(videoPlaylist.isExported))
    }
        
    private func isInheritingSensitivity(node: NodeEntity) async -> Bool {
        (try? await sensitiveNodeUseCase.isInheritingSensitivity(node: node)) ?? false
    }
    
    private func updatedVideoNodes() -> AnyAsyncSequence<[NodeEntity]> {
        nodeRepository
            .nodeUpdates
            .filter { $0.contains { node in node.name.fileExtensionGroup.isVideo }}
            .eraseToAnyAsyncSequence()
    }
    
    private func playlistVideosOnFolderSensitivityChanged(in playlist: VideoPlaylistEntity) -> AnyAsyncSequence<[NodeEntity]> {
        sensitiveNodeUseCase
            .folderSensitivityChanged()
            .map { try await videos(in: playlist) }
            .eraseToAnyAsyncSequence()
    }
    
    private func contentUpdated(in playlist: VideoPlaylistEntity) -> AnyAsyncSequence<[NodeEntity]> {
        userVideoPlaylistRepository
            .playlistContentUpdated(by: playlist.id)
            .compactMap { _ in try? await videos(in: playlist) }
            .eraseToAnyAsyncSequence()
    }
    
    private func nodesUpdated(in playlist: VideoPlaylistEntity) -> AnyAsyncSequence<[NodeEntity]> {
        switch playlist.type {
        case .favourite:
            EmptyAsyncSequence<[NodeEntity]>().eraseToAnyAsyncSequence()
        case .user:
            updatedVideoNodes()
                .compactMap { updatedPhotos -> [NodeEntity]? in
                    let playlistVideoIds = await userVideoPlaylistRepository.videoPlaylistContent(
                        by: playlist.id,
                        includeElementsInRubbishBin: false)
                    guard playlistVideoIds.isNotEmpty,
                          updatedPhotos.contains(where: { photoNode in playlistVideoIds.contains(where: { albumPhotoId in albumPhotoId.nodeId == photoNode.handle }) })
                    else { return nil }
                    return try await videos(in: playlist)
                }
                .eraseToAnyAsyncSequence()
        }
    }
}
