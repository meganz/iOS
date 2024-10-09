import AsyncAlgorithms
import Combine
import Foundation

public protocol AlbumListUseCaseProtocol: Sendable {
    var albumsUpdatedPublisher: AnyPublisher<Void, Never> { get }
    func systemAlbums() async throws -> [AlbumEntity]
    func userAlbums() async -> [AlbumEntity]
    func createUserAlbum(with name: String?) async throws -> AlbumEntity
    func hasNoVisualMedia() async -> Bool
}

public struct AlbumListUseCase: AlbumListUseCaseProtocol {
    
    private let photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    private let mediaUseCase: any MediaUseCaseProtocol
    private let userAlbumRepository: any UserAlbumRepositoryProtocol
    private let albumContentsUpdateRepository: any AlbumContentsUpdateNotifierRepositoryProtocol
    private let albumContentsUseCase: any AlbumContentsUseCaseProtocol
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    
    public var albumsUpdatedPublisher: AnyPublisher<Void, Never> {
        userAlbumUpdates
            .merge(with: albumContentsUpdateRepository.albumReloadPublisher)
            .eraseToAnyPublisher()
    }
    
    private var userAlbumUpdates: AnyPublisher<Void, Never> {
        userAlbumRepository.setsUpdatedPublisher
            .filter { $0.isNotEmpty }
            .map { _ in () }
            .eraseToAnyPublisher()
            .merge(with: userAlbumRepository.setElementsUpdatedPublisher
                .filter { $0.isNotEmpty }
                .map { _ in () }
                .eraseToAnyPublisher())
            .eraseToAnyPublisher()
    }
    
    public init(
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol,
        mediaUseCase: some MediaUseCaseProtocol,
        userAlbumRepository: some UserAlbumRepositoryProtocol,
        albumContentsUpdateRepository: some AlbumContentsUpdateNotifierRepositoryProtocol,
        albumContentsUseCase: some AlbumContentsUseCaseProtocol,
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol
    ) {
        self.photoLibraryUseCase = photoLibraryUseCase
        self.mediaUseCase = mediaUseCase
        self.userAlbumRepository = userAlbumRepository
        self.albumContentsUpdateRepository = albumContentsUpdateRepository
        self.albumContentsUseCase = albumContentsUseCase
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
    }
    
    public func systemAlbums() async throws -> [AlbumEntity] {
        let allPhotos = try await allSortedThumbnailPhotosAndVideos()
        return await createSystemAlbums(allPhotos)
    }
    
    public func userAlbums() async -> [AlbumEntity] {
        let albums = await userAlbumRepository.albums()
        let excludeSensitive = await sensitiveDisplayPreferenceUseCase.excludeSensitives()
        
        return await withTaskGroup(of: AlbumEntity.self,
                                   returning: [AlbumEntity].self) { group in
            albums.forEach { setEntity in
                group.addTask {
                    let userAlbumContent = await albumContentsUseCase.userAlbumPhotos(by: setEntity.handle,
                                                                                      excludeSensitive: excludeSensitive)
                    let coverNode = await albumCoverNode(forAlbum: setEntity,
                                                         albumContent: userAlbumContent)
                    return AlbumEntity(id: setEntity.handle,
                                       name: setEntity.name,
                                       coverNode: coverNode,
                                       count: userAlbumContent.count,
                                       type: .user,
                                       creationTime: setEntity.creationTime,
                                       modificationTime: setEntity.modificationTime,
                                       sharedLinkStatus: .exported(setEntity.isExported),
                                       metaData: makeAlbumMetaData(albumContent: userAlbumContent))
                }
            }
            return await group.reduce(into: [AlbumEntity]()) {
                $0.append($1)
            }
        }
    }
    
    public func createUserAlbum(with name: String?) async throws -> AlbumEntity {
        let setEntity = try await userAlbumRepository.createAlbum(name)
        return AlbumEntity(id: setEntity.handle,
                           name: setEntity.name,
                           coverNode: nil,
                           count: 0,
                           type: .user,
                           creationTime: setEntity.creationTime,
                           modificationTime: setEntity.modificationTime,
                           sharedLinkStatus: .exported(false))
    }
    
    public func hasNoVisualMedia() async -> Bool {
        await ![PhotosFilterOptionsEntity.images, .videos]
            .async
            .contains { visualMediaOption in
                guard let mediaForType = try? await photoLibraryUseCase.media(for: [visualMediaOption, .allLocations],
                                                                              excludeSensitive: nil) else {
                    return true
                }
                return mediaForType.contains(where: { $0.hasThumbnail && $0.name.fileExtensionGroup.isVisualMedia })
            }
    }
    
    // MARK: - Private
    
    private func allSortedThumbnailPhotosAndVideos() async throws -> [NodeEntity] {
        var allPhotos = try await photoLibraryUseCase.media(for: [.allMedia, .allLocations],
                                                            excludeSensitive: nil)
            .filter { $0.hasThumbnail && $0.name.fileExtensionGroup.isVisualMedia }
        
        allPhotos.sort {
            if $0.modificationTime == $1.modificationTime {
                return $0.handle > $1.handle
            }
            return $0.modificationTime > $1.modificationTime
        }
        return allPhotos
    }
    
    private func createSystemAlbums(_ photos: [NodeEntity]) async -> [AlbumEntity] {
        var coverOfFavouritePhoto: NodeEntity?
        var coverOfGifPhoto: NodeEntity?
        var coverOfRawPhoto: NodeEntity?
        var numOfFavouritePhotos = 0
        var numOfGifPhotos = 0
        var numOfRawPhotos = 0
        
        photos.forEach { photo in
            if photo.isFavourite {
                numOfFavouritePhotos += 1
                if coverOfFavouritePhoto == nil { coverOfFavouritePhoto = photo }
            }
            if mediaUseCase.isRawImage(photo.name) {
                numOfRawPhotos += 1
                if coverOfRawPhoto == nil { coverOfRawPhoto = photo }
            } else if mediaUseCase.isGifImage(photo.name) {
                numOfGifPhotos += 1
                if coverOfGifPhoto == nil { coverOfGifPhoto = photo }
            }
        }
        
        var albums = [AlbumEntity]()
        albums.append(AlbumEntity(id: AlbumIdEntity.favourite.value, name: "", coverNode: coverOfFavouritePhoto, count: numOfFavouritePhotos, type: .favourite))
        
        if let coverOfGifPhoto {
            albums.append(AlbumEntity(id: AlbumIdEntity.gif.value, name: "", coverNode: coverOfGifPhoto, count: numOfGifPhotos, type: .gif))
        }
        
        if let coverOfRawPhoto {
            albums.append(AlbumEntity(id: AlbumIdEntity.raw.value, name: "", coverNode: coverOfRawPhoto, count: numOfRawPhotos, type: .raw))
        }
        
        return albums
    }
    
    private func albumCoverNode(forAlbum entity: SetEntity, albumContent: [AlbumPhotoEntity]) async -> NodeEntity? {
        if entity.coverId != .invalid,
           let albumCoverSetElement = await userAlbumRepository.albumElement(by: entity.handle,
                                                                             elementId: entity.coverId),
           let albumCover = albumContent.first(where: { $0.id == albumCoverSetElement.nodeId }) {
            return albumCover.photo
        }
        return albumContent.latestModifiedPhoto()
    }
    
    private func makeAlbumMetaData(albumContent: [AlbumPhotoEntity]) -> AlbumMetaDataEntity {
        let counts = albumContent
            .reduce(into: (image: 0, video: 0)) { (result, content) in
                let fileExtensionGroup = content.photo.name.fileExtensionGroup
                if fileExtensionGroup.isImage {
                    result.image += 1
                } else if fileExtensionGroup.isVideo {
                    result.video += 1
                }
            }
        
        return AlbumMetaDataEntity(imageCount: counts.image,
                                   videoCount: counts.video)
    }
}
