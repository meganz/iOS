import MEGASwift

public protocol MonitorAlbumsUseCaseProtocol {
    /// Infinite `AnyAsyncSequence` returning system albums (Favourite, Raw and Gif)
    ///
    /// The async sequence will immediately return system albums then updates when photo updates occur.
    /// The async sequence is infinite and will require cancellation.
    ///
    /// - Throws: `CancellationError`
    func monitorSystemAlbums() async throws -> AnyAsyncSequence<[AlbumEntity]>
    
    /// Infinite `AnyAsyncSequence` returning user created albums
    ///
    /// The async sequence will immediately return user albums then updates when set updates occur.
    /// The async sequence is infinite and will require cancellation.
    ///
    /// - Throws: `CancellationError`
    func monitorUserAlbums() async throws -> AnyAsyncSequence<[AlbumEntity]>
}

public struct MonitorAlbumsUseCase: MonitorAlbumsUseCaseProtocol {
    private let monitorPhotosUseCase: any MonitorPhotosUseCaseProtocol
    private let mediaUseCase: any MediaUseCaseProtocol
    private let userAlbumRepository: any UserAlbumRepositoryProtocol
    private let photosRepository: any PhotosRepositoryProtocol
    
    public init(monitorPhotosUseCase: some MonitorPhotosUseCaseProtocol,
                mediaUseCase: some MediaUseCaseProtocol,
                userAlbumRepository: some UserAlbumRepositoryProtocol,
                photosRepository: some PhotosRepositoryProtocol) {
        self.monitorPhotosUseCase = monitorPhotosUseCase
        self.mediaUseCase = mediaUseCase
        self.userAlbumRepository = userAlbumRepository
        self.photosRepository = photosRepository
    }
    
    public func monitorSystemAlbums() async throws -> AnyAsyncSequence<[AlbumEntity]> {
        try await monitorPhotosUseCase.monitorPhotos(filterOptions: [.allLocations, .allMedia])
            .map {
                makeSystemAlbums($0)
            }
            .eraseToAnyAsyncSequence()
    }
    
    public func monitorUserAlbums() async -> AnyAsyncSequence<[AlbumEntity]> {
        let albums = await userAlbumRepository.albums()
        
        return await userAlbumRepository.albumsUpdated()
            .prepend(albums)
            .map {
                await makeUserAlbums($0)
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
        
        photos.forEach { photo in
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
    
    private func makeUserAlbums(_ albumSets: [SetEntity]) async -> [AlbumEntity] {
        await withTaskGroup(of: AlbumEntity.self,
                            returning: [AlbumEntity].self) { group in
            albumSets.forEach { setEntity in
                group.addTask {
                    let coverNode = await userAlbumCoverNode(for: setEntity)
                    return AlbumEntity(id: setEntity.handle,
                                       name: setEntity.name,
                                       coverNode: coverNode,
                                       count: 0,
                                       type: .user,
                                       creationTime: setEntity.creationTime,
                                       modificationTime: setEntity.modificationTime,
                                       sharedLinkStatus: .exported(setEntity.isExported))
                }
            }
            return await group.reduce(into: [AlbumEntity]()) {
                $0.append($1)
            }
        }
    }
    
    private func userAlbumCoverNode(for set: SetEntity) async -> NodeEntity? {
        guard set.coverId != .invalid,
              let albumCover = await userAlbumRepository.albumElementId(by: set.handle,
                                                                        elementId: set.coverId) else {
            return nil
        }
        return await photosRepository.photo(forHandle: albumCover.nodeId)
    }
}
