import AsyncAlgorithms
import MEGASwift

public protocol MonitorUserAlbumPhotosUseCaseProtocol: Sendable {
    /// Infinite `AnyAsyncSequence` returning user album photos.
    ///
    /// The async sequence will immediately return album photos
    /// The async sequence is infinite and will require cancellation.
    /// - Parameters:
    ///   - album: The album entity for which to monitor the photos.
    ///   - excludeSensitives: A boolean value indicating whether to exclude sensitive photos from album covers.
    /// - Returns: AnyAsyncSequence<[AlbumPhotoEntity]> that will yield photos for a user album
    /// (contains `NodeEntity` and optional link to the `SetEntityElement` handle).
    /// - Important: If `excludeSensitives` is set to `true`, the sequence will exclude sensitive photos that are marked as sensitive or have inherited sensitivity.
    func monitorUserAlbumPhotos(
        for album: AlbumEntity,
        excludeSensitives: Bool
    ) async -> AnyAsyncSequence<[AlbumPhotoEntity]>
}

public struct MonitorUserAlbumPhotosUseCase: MonitorUserAlbumPhotosUseCaseProtocol {
    private let userAlbumRepository: any UserAlbumRepositoryProtocol
    private let photosRepository: any PhotosRepositoryProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    
    public init(userAlbumRepository: some UserAlbumRepositoryProtocol,
                photosRepository: some PhotosRepositoryProtocol,
                sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol) {
        self.userAlbumRepository = userAlbumRepository
        self.photosRepository = photosRepository
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
    }
    
    public func monitorUserAlbumPhotos(
        for album: AlbumEntity,
        excludeSensitives: Bool
    ) async -> AnyAsyncSequence<[AlbumPhotoEntity]> {
        guard album.type == .user else {
            return EmptyAsyncSequence<[AlbumPhotoEntity]>().eraseToAnyAsyncSequence()
        }
        return await merge(userAlbumContentUpdated(album: album),
                           userAlbumPhotoUpdated(album: album),
                           albumPhotosOnFolderSensitivityChanged(album: album))
        .prepend {
            await userAlbumRepository.albumElementIds(
                by: album.id, includeElementsInRubbishBin: false)
        }
        .map {
            await userAlbumPhotos(forAlbumPhotoIds: $0,
                                  excludeSensitives: excludeSensitives)
        }
        .eraseToAnyAsyncSequence()
    }
    
    // MARK: Private
    
    private func userAlbumContentUpdated(album: AlbumEntity) async -> AnyAsyncSequence<[AlbumPhotoIdEntity]> {
        await userAlbumRepository.albumContentUpdated(by: album.id)
            .filter { $0.isNotEmpty }
            .map { _ in
                await userAlbumRepository.albumElementIds(by: album.id,
                                                          includeElementsInRubbishBin: false)
            }
            .eraseToAnyAsyncSequence()
    }
    
    private func userAlbumPhotoUpdated(album: AlbumEntity) async -> AnyAsyncSequence<[AlbumPhotoIdEntity]> {
        guard album.type == .user else {
            return EmptyAsyncSequence<[AlbumPhotoIdEntity]>().eraseToAnyAsyncSequence()
        }
        return await photosRepository.photosUpdated()
            .compactMap { updatedPhotos -> [AlbumPhotoIdEntity]? in
                let albumPhotoIds = await userAlbumRepository.albumElementIds(by: album.id,
                                                                              includeElementsInRubbishBin: false)
                guard albumPhotoIds.isNotEmpty,
                      updatedPhotos.contains(where: { photoNode in
                          albumPhotoIds.contains(where: { albumPhotoId in albumPhotoId.nodeId == photoNode.handle })
                      }) else { return nil }
                return albumPhotoIds
            }
            .eraseToAnyAsyncSequence()
    }
    
    private func albumPhotosOnFolderSensitivityChanged(album: AlbumEntity) -> AnyAsyncSequence<[AlbumPhotoIdEntity]> {
        sensitiveNodeUseCase.folderSensitivityChanged()
            .map {
                await userAlbumRepository.albumElementIds(by: album.id,
                                                          includeElementsInRubbishBin: false)
            }
            .eraseToAnyAsyncSequence()
    }
    
    private func userAlbumPhotos(forAlbumPhotoIds albumPhotoIds: [AlbumPhotoIdEntity],
                                 excludeSensitives: Bool) async -> [AlbumPhotoEntity] {
        await withTaskGroup(of: AlbumPhotoEntity?.self) { group in
            for albumElementId in albumPhotoIds {
                guard group.addTaskUnlessCancelled(operation: {
                    guard let photo = await photosRepository.photo(
                        forHandle: albumElementId.nodeId, excludeSensitive: excludeSensitives) else {
                        return nil
                    }
                    return AlbumPhotoEntity(photo: photo,
                                            albumPhotoId: albumElementId.id)
                }) else { break }
            }
            
            return await group.reduce(into: [AlbumPhotoEntity](), {
                if let photo = $1 { $0.append(photo) }
            })
        }
    }
}
