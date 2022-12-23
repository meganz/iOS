import Foundation

public protocol AlbumListUseCaseProtocol {
    func loadCameraUploadNode() async throws -> NodeEntity?
    func loadAlbums() async -> [AlbumEntity]
    func startMonitoringNodesUpdate(callback: @escaping () -> Void)
    func stopMonitoringNodesUpdate()
    func createUserAlbum(with name: String?) async throws -> AlbumEntity
}

public final class AlbumListUseCase<T: AlbumRepositoryProtocol, U: FileSearchRepositoryProtocol, V: MediaUseCaseProtocol, W: UserAlbumRepositoryProtocol>:
    AlbumListUseCaseProtocol {
    
    private let albumRepository: T
    private let fileSearchRepository: U
    private let mediaUseCase: V
    private let userAlbumRepository: W
    
    private var callback: (() -> Void)?
    
    public init(
        albumRepository: T,
        userAlbumRepository: W,
        fileSearchRepository: U,
        mediaUseCase: V
    ) {
        self.albumRepository = albumRepository
        self.userAlbumRepository = userAlbumRepository
        self.fileSearchRepository = fileSearchRepository
        self.mediaUseCase = mediaUseCase
    }
    
    public func loadCameraUploadNode() async throws -> NodeEntity? {
        return try await albumRepository.loadCameraUploadNode()
    }
    
    public func loadAlbums() async -> [AlbumEntity] {
        async let userAlbums = loadUserAlbums()
        async let systemAlbums = try? loadSystemAlbums()
        return await (systemAlbums ?? []) + userAlbums
    }
    
    public func startMonitoringNodesUpdate(callback: @escaping () -> Void) {
        self.callback = callback
        fileSearchRepository.startMonitoringNodesUpdate(callback: onNodesUpdate)
    }
    
    public func stopMonitoringNodesUpdate() {
        self.callback = nil
        fileSearchRepository.stopMonitoringNodesUpdate()
    }
    
    // MARK: - Private
    
    private func loadSystemAlbums() async throws -> [AlbumEntity] {
        let allPhotos = try await allSortedThumbnailPhotosAndVideos()
        return await createSystemAlbums(allPhotos)
    }
    
    private func allSortedThumbnailPhotosAndVideos() async throws -> [NodeEntity] {
        async let allPhotos = try await fileSearchRepository.allPhotos()
        async let allVideos = try await fileSearchRepository.allVideos()
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
    
    private func onNodesUpdate(_ nodes: [NodeEntity]) {
        callback?()
    }
    
    public func createUserAlbum(with name: String?) async throws -> AlbumEntity {
        let setEntity = try await userAlbumRepository.createAlbum(name)
        return AlbumEntity(id: setEntity.handle,
                           name: setEntity.name,
                           coverNode: nil,
                           count: 0,
                           type: .user)
    }
    
    private func loadUserAlbums() async -> [AlbumEntity] {
        await userAlbumRepository.albums()
            .map({ AlbumEntity(id: $0.handle,
                               name: $0.name,
                               coverNode: fileSearchRepository.fetchNode(by: $0.coverId),
                               count: $0.size,
                               type: .user)
            })
    }
}
