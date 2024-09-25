import MEGASwift

public protocol MonitorAlbumPhotosUseCaseProtocol: Sendable {
    /// Async sequence returning system album photos.
    ///
    /// The async sequence will immediately return album photos
    /// - Parameters:
    ///   - album: The album photos to monitor.
    /// - Returns: An asynchronous sequence of results, where each result contains an array of `AlbumPhotoEntity` objects or an error.
    func monitorPhotos(
        for album: AlbumEntity
    ) async -> AnyAsyncSequence<Result<[AlbumPhotoEntity], Error>>
}

public struct MonitorAlbumPhotosUseCase: MonitorAlbumPhotosUseCaseProtocol {
    private let monitorSystemAlbumPhotosUseCase: any MonitorSystemAlbumPhotosUseCaseProtocol
    private let monitorUserAlbumPhotosUseCase: any MonitorUserAlbumPhotosUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let hiddenNodesFeatureFlagEnabled: @Sendable () -> Bool
    
    public init(
        monitorSystemAlbumPhotosUseCase: some MonitorSystemAlbumPhotosUseCaseProtocol,
        monitorUserAlbumPhotosUseCase: some MonitorUserAlbumPhotosUseCaseProtocol,
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
        hiddenNodesFeatureFlagEnabled: @escaping @Sendable () -> Bool
    ) {
        self.monitorSystemAlbumPhotosUseCase = monitorSystemAlbumPhotosUseCase
        self.monitorUserAlbumPhotosUseCase = monitorUserAlbumPhotosUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.hiddenNodesFeatureFlagEnabled = hiddenNodesFeatureFlagEnabled
    }
    
    public func monitorPhotos(
        for album: AlbumEntity
    ) async -> AnyAsyncSequence<Result<[AlbumPhotoEntity], any Error>> {
        let shouldExcludeSensitive = await shouldExcludeSensitive()
        
        return switch album.type {
        case .user:
            await userAlbumPhotos(album: album, excludeSensitives: shouldExcludeSensitive)
        case .favourite, .raw, .gif:
            await systemAlbumPhotos(albumType: album.type, excludeSensitives: shouldExcludeSensitive)
        }
    }
    
    private func userAlbumPhotos(album: AlbumEntity, excludeSensitives: Bool) async -> AnyAsyncSequence<Result<[AlbumPhotoEntity], any Error>> {
        await monitorUserAlbumPhotosUseCase.monitorUserAlbumPhotos(
            for: album,
            excludeSensitives: excludeSensitives)
        .map {
            Result<[AlbumPhotoEntity], any Error>.success($0)
        }
        .eraseToAnyAsyncSequence()
    }
    
    private func systemAlbumPhotos(albumType: AlbumEntityType, excludeSensitives: Bool) async -> AnyAsyncSequence<Result<[AlbumPhotoEntity], any Error>> {
        await monitorSystemAlbumPhotosUseCase.monitorPhotos(
            for: albumType,
            excludeSensitive: excludeSensitives)
        .map {
            $0.map { $0.map { AlbumPhotoEntity(photo: $0) } }
        }
        .eraseToAnyAsyncSequence()
    }
    
    private func shouldExcludeSensitive() async -> Bool {
        if hiddenNodesFeatureFlagEnabled() {
            await !contentConsumptionUserAttributeUseCase.fetchSensitiveAttribute().showHiddenNodes
        } else {
            false
        }
    }
}
