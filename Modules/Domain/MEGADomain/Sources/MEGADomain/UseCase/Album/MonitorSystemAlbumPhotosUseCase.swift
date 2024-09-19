import MEGASwift

public protocol MonitorSystemAlbumPhotosUseCaseProtocol: Sendable {
    /// Async sequence returning system album photos.
    ///
    /// The async sequence will immediately return album photos
    /// - Parameters:
    ///   - albumType: The album type photos to monitor.
    /// - Returns: An asynchronous sequence of results, where each result contains an array of `NodeEntity` objects or an error.
    func monitorPhotos(for albumType: AlbumEntityType) async -> AnyAsyncSequence<Result<[NodeEntity], Error>>
}

public struct MonitorSystemAlbumPhotosUseCase: MonitorSystemAlbumPhotosUseCaseProtocol {
    private let monitorPhotosUseCase: any MonitorPhotosUseCaseProtocol
    private let mediaUseCase: any MediaUseCaseProtocol
    
    public init(monitorPhotosUseCase: some MonitorPhotosUseCaseProtocol,
                mediaUseCase: some MediaUseCaseProtocol) {
        self.monitorPhotosUseCase = monitorPhotosUseCase
        self.mediaUseCase = mediaUseCase
    }
    
    public func monitorPhotos(for albumType: AlbumEntityType) async -> AnyAsyncSequence<Result<[NodeEntity], Error>> {
        guard albumType != .user else {
            return SingleItemAsyncSequence(item: .failure(AlbumErrorEntity.invalidType))
                .eraseToAnyAsyncSequence()
        }
        var filterOptions: PhotosFilterOptionsEntity = [.allLocations, .allMedia]
        if albumType == .favourite {
            filterOptions.insert(.favourites)
        }
        return await monitorPhotosUseCase.monitorPhotos(filterOptions: filterOptions)
            .map {
                $0.map { makeSystemAlbum(for: albumType, photos: $0) }
            }
            .eraseToAnyAsyncSequence()
    }
    
    private func makeSystemAlbum(for type: AlbumEntityType, photos: [NodeEntity]) -> [NodeEntity] {
        switch type {
        case .raw: photos.filter { mediaUseCase.isRawImage($0.name) }
        case .gif: photos.filter { mediaUseCase.isGifImage($0.name) }
        default: photos
        }
    }
}
