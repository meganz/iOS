import Foundation

public protocol AlbumListUseCaseProtocol {
    func loadCameraUploadNode() async throws -> NodeEntity?
    func loadAlbums() async throws -> [AlbumEntity]
    func startMonitoringNodesUpdate(callback: @escaping () -> Void)
    func stopMonitoringNodesUpdate()
}

public final class AlbumListUseCase<T: AlbumRepositoryProtocol, U: FileSearchRepositoryProtocol, V: MediaUseCaseProtocol>:
    AlbumListUseCaseProtocol {
    
    private let albumRepository: T
    private let fileSearchRepository: U
    private let mediaUseCase: V
    
    private var callback: (() -> Void)?
    
    public init(
        albumRepository: T,
        fileSearchRepository: U,
        mediaUseCase: V
    ) {
        self.albumRepository = albumRepository
        self.fileSearchRepository = fileSearchRepository
        self.mediaUseCase = mediaUseCase
    }
    
    public func loadCameraUploadNode() async throws -> NodeEntity? {
        return try await albumRepository.loadCameraUploadNode()
    }
    
    public func loadAlbums() async throws -> [AlbumEntity] {
        try await loadSystemAlbums()
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
        let allPhotos = try await fileSearchRepository.allPhotos().filter { $0.hasThumbnail }
        return await createSystemAlbums(allPhotos)
    }
    
    private func createSystemAlbums(_ photos: [NodeEntity]) async -> [AlbumEntity] {
        var coverOfGifPhoto: NodeEntity?
        var coverOfRawPhoto: NodeEntity?
        var numOfGifPhotos = 0
        var numOfRawPhotos = 0
        
        photos.forEach { photo in
            if mediaUseCase.isRawImage(photo.name) {
                numOfRawPhotos += 1
                if coverOfRawPhoto == nil { coverOfRawPhoto = photo }
            } else if mediaUseCase.isGifImage(photo.name){
                numOfGifPhotos += 1
                if coverOfGifPhoto == nil { coverOfGifPhoto = photo }
            }
        }
        
        var albums = [AlbumEntity]()
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
}
