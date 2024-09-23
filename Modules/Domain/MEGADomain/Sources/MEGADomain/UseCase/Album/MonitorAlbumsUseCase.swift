import AsyncAlgorithms
import MEGASwift

public protocol MonitorAlbumsUseCaseProtocol: Sendable {
    /// Infinite `AnyAsyncSequence` returning result type of system albums (Favourite, Raw and Gif) or error
    ///
    /// The async sequence will immediately return system albums then updates when photo updates occur.
    /// The async sequence is infinite and will require cancellation.
    /// - Parameter excludeSensitives: A boolean value indicating whether to exclude sensitive photos from album covers. They will always be included in count.
    /// - Returns: An asynchronous sequence of results, where each result contains an array of `AlbumEntity` objects or an error.
    func monitorSystemAlbums(excludeSensitives: Bool) async -> AnyAsyncSequence<Result<[AlbumEntity], Error>>
    
    /// Infinite `AnyAsyncSequence` returning user created albums
    ///
    /// The async sequence will immediately return user albums then updates when set updates occur.
    /// The async sequence is infinite and will require cancellation.
    /// - Parameter excludeSensitives: A boolean value indicating whether to exclude sensitive covers from albums.
    /// - Returns: An asynchronous sequence of `[AlbumEntity]`.
    func monitorUserAlbums(excludeSensitives: Bool) async -> AnyAsyncSequence<[AlbumEntity]>
}

public struct MonitorAlbumsUseCase: MonitorAlbumsUseCaseProtocol {
    private let monitorPhotosUseCase: any MonitorPhotosUseCaseProtocol
    private let mediaUseCase: any MediaUseCaseProtocol
    private let userAlbumRepository: any UserAlbumRepositoryProtocol
    private let photosRepository: any PhotosRepositoryProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    
    public init(monitorPhotosUseCase: some MonitorPhotosUseCaseProtocol,
                mediaUseCase: some MediaUseCaseProtocol,
                userAlbumRepository: some UserAlbumRepositoryProtocol,
                photosRepository: some PhotosRepositoryProtocol,
                sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol) {
        self.monitorPhotosUseCase = monitorPhotosUseCase
        self.mediaUseCase = mediaUseCase
        self.userAlbumRepository = userAlbumRepository
        self.photosRepository = photosRepository
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
    }
    
    public func monitorSystemAlbums(excludeSensitives: Bool) async -> AnyAsyncSequence<Result<[AlbumEntity], Error>> {
        await monitorPhotosUseCase.monitorPhotos(
            filterOptions: [.allLocations, .allMedia],
            excludeSensitive: excludeSensitives
        )
        .map {
            $0.map(makeSystemAlbums(_:))
        }
        .eraseToAnyAsyncSequence()
    }
    
    public func monitorUserAlbums(excludeSensitives: Bool) async -> AnyAsyncSequence<[AlbumEntity]> {
        await userAlbumRepository.albumsUpdated()
            .prepend {
                await userAlbumRepository.albums()
            }
            .map {
                await makeUserAlbums($0, excludeSensitives: excludeSensitives)
            }
            .eraseToAnyAsyncSequence()
    }
    
    // MARK: Private
    
    private func makeSystemAlbums(_ photos: [NodeEntity]) -> [AlbumEntity] {
        var favouriteAlbumCover: NodeEntity?
        var gifAlbumCover: NodeEntity?
        var rawAlbumCover: NodeEntity?
        var numOfFavouritePhotos = 0
        var numOfGifPhotos = 0
        var numOfRawPhotos = 0
        
        for photo in photos {
            if photo.isFavourite {
                numOfFavouritePhotos += 1
                if isPhotoModificationTimeLater(currentPhoto: favouriteAlbumCover,
                                                photo: photo) {
                    favouriteAlbumCover = photo
                }
            }
            if mediaUseCase.isGifImage(photo.name) {
                numOfGifPhotos += 1
                if isPhotoModificationTimeLater(currentPhoto: gifAlbumCover,
                                                photo: photo) {
                    gifAlbumCover = photo
                }
            } else if mediaUseCase.isRawImage(photo.name) {
                numOfRawPhotos += 1
                if isPhotoModificationTimeLater(currentPhoto: rawAlbumCover,
                                                photo: photo) {
                    rawAlbumCover = photo
                }
            }
        }
        
        return makeAlbums(favouriteAlbumCover: favouriteAlbumCover, favouritePhotosCount: numOfFavouritePhotos,
                          gifAlbumCover: gifAlbumCover, gifPhotosCount: numOfGifPhotos,
                          rawAlbumCover: rawAlbumCover, rawPhotosCount: numOfRawPhotos)
    }
    
    private func makeAlbums(favouriteAlbumCover: NodeEntity?, favouritePhotosCount: Int,
                            gifAlbumCover: NodeEntity?, gifPhotosCount: Int,
                            rawAlbumCover: NodeEntity?, rawPhotosCount: Int) -> [AlbumEntity] {
        var albums = [AlbumEntity]()
        albums.append(AlbumEntity(id: AlbumIdEntity.favourite.value, name: "",
                                  coverNode: favouriteAlbumCover, count: favouritePhotosCount, type: .favourite))
        if gifPhotosCount > 0 {
            albums.append(AlbumEntity(id: AlbumIdEntity.gif.value, name: "",
                                      coverNode: gifAlbumCover, count: gifPhotosCount, type: .gif))
        }
        if rawPhotosCount > 0 {
            albums.append(AlbumEntity(id: AlbumIdEntity.raw.value, name: "",
                                      coverNode: rawAlbumCover, count: rawPhotosCount, type: .raw))
        }
        return albums
    }
    
    private func isPhotoModificationTimeLater(currentPhoto: NodeEntity?, photo: NodeEntity) -> Bool {
        guard let currentPhoto else { return true }
        guard photo.modificationTime != currentPhoto.modificationTime else {
            return photo.handle > currentPhoto.handle
        }
        return photo.modificationTime > currentPhoto.modificationTime
    }
    
    private func makeUserAlbums(_ albumSets: [SetEntity], excludeSensitives: Bool) async -> [AlbumEntity] {
        await withTaskGroup(of: AlbumEntity.self,
                            returning: [AlbumEntity].self) { group in
            for setEntity in albumSets {
                guard group.addTaskUnlessCancelled(operation: {
                    let coverNode = await userAlbumCoverNode(for: setEntity, excludeSensitives: excludeSensitives)
                    return AlbumEntity(id: setEntity.handle,
                                       name: setEntity.name,
                                       coverNode: coverNode,
                                       count: 0,
                                       type: .user,
                                       creationTime: setEntity.creationTime,
                                       modificationTime: setEntity.modificationTime,
                                       sharedLinkStatus: .exported(setEntity.isExported))
                }) else { break }
            }
            return await group.reduce(into: [AlbumEntity]()) {
                $0.append($1)
            }
        }
    }
    
    private func userAlbumCoverNode(for set: SetEntity, excludeSensitives: Bool) async -> NodeEntity? {
        guard set.coverId != .invalid,
              let albumCoverElementId = await userAlbumRepository.albumElementId(by: set.handle,
                                                                                 elementId: set.coverId),
              let coverPhoto = await photosRepository.photo(
                forHandle: albumCoverElementId.nodeId, excludeSensitive: excludeSensitives) else {
            return nil
        }
        return coverPhoto
    }
}
