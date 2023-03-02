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
                                    X: AlbumContentsUpdateNotifierRepositoryProtocol>:
    AlbumListUseCaseProtocol {
    
    private let albumRepository: T
    private let fileSearchRepository: U
    private let mediaUseCase: V
    private let userAlbumRepository: W
    private let albumContentsUpdateRepository: X
    
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
        albumContentsUpdateRepository: X
    ) {
        self.albumRepository = albumRepository
        self.fileSearchRepository = fileSearchRepository
        self.mediaUseCase = mediaUseCase
        self.userAlbumRepository = userAlbumRepository
        self.albumContentsUpdateRepository = albumContentsUpdateRepository
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
        let albumCovers = await albumCovers(albums)
        return albums
            .map { AlbumEntity(id: $0.handle,
                               name: $0.name,
                               coverNode: albumCovers[$0.coverId],
                               count: $0.size,
                               type: .user,
                               modificationTime: $0.modificationTime)
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
        var numOfFavouritePhotos: UInt = 0
        var numOfGifPhotos: UInt = 0
        var numOfRawPhotos: UInt = 0
        
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
    
    private func albumCovers(_ albums: [SetEntity]) async -> [HandleEntity: NodeEntity] {
        return await withTaskGroup(of: (HandleEntity, NodeEntity?).self) { taskGroup -> [HandleEntity: NodeEntity] in
            albums.forEach { setEntity in
                taskGroup.addTask {
                    let albumContents = await userAlbumRepository.albumContent(by: setEntity.handle, includeElementsInRubbishBin: false)
                    guard let albumCoverSetElement = albumContents.first(where: {
                        $0.handle == setEntity.coverId
                    }) else {
                        return (setEntity.coverId, nil)
                    }
                    let albumCover = await fileSearchRepository.node(by: albumCoverSetElement.nodeId)
                    return (setEntity.coverId, albumCover)
                }
            }
            return await taskGroup.reduce(into: [HandleEntity: NodeEntity](), {
                if let albumCoverNode = $1.1 {
                    $0[$1.0] = albumCoverNode
                }
            })
        }
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
