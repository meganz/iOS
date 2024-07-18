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
    
    /// Infinite `AnyAsyncSequence` returning user album photos.
    ///
    /// The async sequence will immediately return album photos
    /// The async sequence is infinite and will require cancellation.
    /// - Parameters:
    ///   - album: The album entity for which to monitor the photos.
    ///   - excludeSensitives: A boolean value indicating whether to exclude sensitive photos from album covers.
    ///   - includeSensitiveInherited: A boolean value indicating whether to include inherited sensitivity in `AlbumPhotoEntity`.
    /// - Returns: AnyAsyncSequence<[AlbumPhotoEntity]> that will yield photos for a user album
    /// (contains `NodeEntity` and optional link to the `SetEntityElement` handle).
    /// - Important: If `excludeSensitives` is set to `true`, the sequence will exclude sensitive photos that are marked as sensitive or have inherited sensitivity.
    /// If `includeSensitiveInherited` is set to `true`, the `AlbumPhotoEntity` objects will include inherited sensitivity information.
    func monitorUserAlbumPhotos(for album: AlbumEntity, excludeSensitives: Bool,
                                includeSensitiveInherited: Bool) async -> AnyAsyncSequence<[AlbumPhotoEntity]>
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
        await monitorPhotosUseCase.monitorPhotos(filterOptions: [.allLocations, .allMedia])
            .map {
                switch $0 {
                case .success(let photos):
                        .success(makeSystemAlbums(
                            photos, coverPhotosSensitiveState: await coverPhotoSensitiveState(photos, excludeSensitives: excludeSensitives)))
                case .failure(let error):
                        .failure(error)
                }
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
    
    public func monitorUserAlbumPhotos(for album: AlbumEntity,
                                       excludeSensitives: Bool,
                                       includeSensitiveInherited: Bool) async -> AnyAsyncSequence<[AlbumPhotoEntity]> {
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
                                  excludeSensitives: excludeSensitives,
                                  includeSensitiveInherited: includeSensitiveInherited)
        }
        .eraseToAnyAsyncSequence()
    }
    
    // MARK: Private
    
    private func makeSystemAlbums(_ photos: [NodeEntity], coverPhotosSensitiveState: [HandleEntity: Bool]?) -> [AlbumEntity] {
        var favouriteAlbumCover: NodeEntity?
        var gifAlbumCover: NodeEntity?
        var rawAlbumCover: NodeEntity?
        var numOfFavouritePhotos = 0
        var numOfGifPhotos = 0
        var numOfRawPhotos = 0
        
        for photo in photos {
            guard coverPhotosSensitiveState?[photo.handle] ?? true else { continue }
            
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
              let coverPhoto = await photosRepository.photo(forHandle: albumCoverElementId.nodeId),
              await shouldShowPhoto(coverPhoto, excludeSensitives: excludeSensitives) else {
            return nil
        }
        return coverPhoto
    }
    
    private func userAlbumPhotos(forAlbumPhotoIds albumPhotoIds: [AlbumPhotoIdEntity],
                                 excludeSensitives: Bool,
                                 includeSensitiveInherited: Bool) async -> [AlbumPhotoEntity] {
        await withTaskGroup(of: AlbumPhotoEntity?.self) { group in
            for albumElementId in albumPhotoIds {
                guard group.addTaskUnlessCancelled(operation: {
                    guard let photo = await photosRepository.photo(forHandle: albumElementId.nodeId) else {
                        return nil
                    }
                    guard excludeSensitives || includeSensitiveInherited else {
                        return AlbumPhotoEntity(photo: photo, albumPhotoId: albumElementId.id)
                    }
                    guard !(excludeSensitives && photo.isMarkedSensitive) else {
                        return nil
                    }
                    let isSensitiveInherited = await isInheritingSensitivity(node: photo)
                    guard !(excludeSensitives && isSensitiveInherited) else {
                        return nil
                    }
                    return AlbumPhotoEntity(photo: photo,
                                            albumPhotoId: albumElementId.id,
                                            isSensitiveInherited: includeSensitiveInherited ? isSensitiveInherited : nil)
                }) else { break }
            }
            
            return await group.reduce(into: [AlbumPhotoEntity](), {
                if let photo = $1 { $0.append(photo) }
            })
        }
    }
    
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
    
    private func coverPhotoSensitiveState(_ photos: [NodeEntity], excludeSensitives: Bool) async -> [HandleEntity: Bool]? {
        guard excludeSensitives else { return nil }
        
        return await withTaskGroup(of: (HandleEntity, Bool).self,
                                   returning: [HandleEntity: Bool].self) { group in
            for photo in photos {
                guard group.addTaskUnlessCancelled(operation: {
                    (photo.handle, await shouldShowPhoto(photo, excludeSensitives: excludeSensitives))
                }) else {
                    break
                }
            }
            
            return await group.reduce(into: [HandleEntity: Bool]()) {
                $0[$1.0] = $1.1
            }
        }
    }
    
    private func shouldShowPhoto(_ node: NodeEntity, excludeSensitives: Bool) async -> Bool {
        if !excludeSensitives {
            true
        } else if node.isMarkedSensitive {
            false
        } else {
            await !isInheritingSensitivity(node: node)
        }
    }
    
    private func isInheritingSensitivity(node: NodeEntity) async -> Bool {
        (try? await sensitiveNodeUseCase.isInheritingSensitivity(node: node)) ?? false
    }
    
    private func albumPhotosOnFolderSensitivityChanged(album: AlbumEntity) -> AnyAsyncSequence<[AlbumPhotoIdEntity]> {
        sensitiveNodeUseCase.folderSensitivityChanged()
            .map {
                await userAlbumRepository.albumElementIds(by: album.id,
                                                          includeElementsInRubbishBin: false)
            }
            .eraseToAnyAsyncSequence()
    }
}
