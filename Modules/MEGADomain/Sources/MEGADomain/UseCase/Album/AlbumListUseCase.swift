import Foundation
import Combine

public protocol AlbumListUseCaseProtocol {
    var albumsUpdatedPublisher: AnyPublisher<Void, Never> { get }
    func loadCameraUploadNode() async throws -> NodeEntity?
    func systemAlbums() async throws -> [AlbumEntity]
    func userAlbums() async -> [AlbumEntity]
    func createUserAlbum(with name: String?) async throws -> AlbumEntity
    func hasNoPhotosAndVideos() async -> Bool
}

public struct AlbumListUseCase<T: AlbumRepositoryProtocol, U: FilesSearchRepositoryProtocol,
                               V: MediaUseCaseProtocol, W: UserAlbumRepositoryProtocol,
                               X: AlbumContentsUpdateNotifierRepositoryProtocol, Y: AlbumContentsUseCaseProtocol>:
                                AlbumListUseCaseProtocol {
    
    private let albumRepository: T
    private let fileSearchRepository: U
    private let mediaUseCase: V
    private let userAlbumRepository: W
    private let albumContentsUpdateRepository: X
    private let albumContentsUseCase: Y
    
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
            .merge(with: userAlbumRepository.setElemetsUpdatedPublisher
                .filter { $0.isNotEmpty }
                .map { _ in () }
                .eraseToAnyPublisher())
            .eraseToAnyPublisher()
    }
    
    public init(
        albumRepository: T,
        userAlbumRepository: W,
        fileSearchRepository: U,
        mediaUseCase: V,
        albumContentsUpdateRepository: X,
        albumContentsUseCase: Y
    ) {
        self.albumRepository = albumRepository
        self.fileSearchRepository = fileSearchRepository
        self.mediaUseCase = mediaUseCase
        self.userAlbumRepository = userAlbumRepository
        self.albumContentsUpdateRepository = albumContentsUpdateRepository
        self.albumContentsUseCase = albumContentsUseCase
    }
    
    public func loadCameraUploadNode() async throws -> NodeEntity? {
        return try await albumRepository.loadCameraUploadNode()
    }
    
    public func systemAlbums() async throws -> [AlbumEntity] {
        let allPhotos = try await allSortedThumbnailPhotosAndVideos()
        return await createSystemAlbums(allPhotos)
    }
    
    public func userAlbums() async -> [AlbumEntity] {
        let albums = await userAlbumRepository.albums()
        return await withTaskGroup(of: AlbumEntity.self,
                                   returning: [AlbumEntity].self) { group in
            albums.forEach { setEntity in
                group.addTask {
                    var userAlbumContent = await albumContentsUseCase.userAlbumPhotos(by: setEntity.handle)
                    let coverNode = await albumCoverNode(forAlbum: setEntity,
                                                         albumContent: &userAlbumContent)
                    return AlbumEntity(id: setEntity.handle,
                                       name: setEntity.name,
                                       coverNode: coverNode,
                                       count: userAlbumContent.count,
                                       type: .user,
                                       modificationTime: setEntity.modificationTime)
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
                           modificationTime: setEntity.modificationTime)
    }
    
    // MARK: - Private
    
    private func allPhotos() async throws -> [NodeEntity] {
        try await fileSearchRepository.search(string: "",
                                              parent: nil,
                                              supportCancel: false,
                                              sortOrderType: .defaultDesc,
                                              formatType: .photo)
    }
    
    private func allVideos() async throws -> [NodeEntity] {
        try await fileSearchRepository.search(string: "",
                                              parent: nil,
                                              supportCancel: false,
                                              sortOrderType: .defaultDesc,
                                              formatType: .video)
    }
    
    private func allSortedThumbnailPhotosAndVideos() async throws -> [NodeEntity] {
        async let allPhotos = try await allPhotos()
        async let allVideos = try await allVideos()
        var allThumbnailPhotosAndVideos = try await [allPhotos, allVideos]
            .flatMap { $0 }
            .filter { $0.hasThumbnail }
        allThumbnailPhotosAndVideos.sort {
            if $0.modificationTime == $1.modificationTime {
                return $0.handle > $1.handle
            }
            return $0.modificationTime > $1.modificationTime
        }
        return allThumbnailPhotosAndVideos
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
            } else if mediaUseCase.isGifImage(photo.name){
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
    
    private func albumCoverNode(forAlbum entity: SetEntity, albumContent: inout [AlbumPhotoEntity]) async -> NodeEntity? {
        if entity.coverId != .invalid,
           let albumCoverSetElement = await userAlbumRepository.albumElement(by: entity.handle,
                                                                             elementId: entity.coverId),
           let albumCover = albumContent.first(where: { $0.id == albumCoverSetElement.nodeId }) {
            return albumCover.photo
        }
        albumContent.sort {
            if $0.photo.modificationTime == $1.photo.modificationTime {
                return $0.id > $1.id
            }
            return $0.photo.modificationTime > $1.photo.modificationTime
        }
        return albumContent.first?.photo
    }
    
    public func hasNoPhotosAndVideos() async -> Bool {
        async let allPhotos = try await allPhotos()
        async let allVideos = try await allVideos()
        let allPhotosAndVideos = try? await [allPhotos, allVideos]
            .flatMap { $0 }
            .filter { $0.hasThumbnail }
        return allPhotosAndVideos?.isEmpty ?? true
    }
}
