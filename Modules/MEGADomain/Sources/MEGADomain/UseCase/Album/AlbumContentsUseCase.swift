import Combine

public protocol AlbumContentsUseCaseProtocol {
    var updatePublisher: AnyPublisher<Void, Never> { get }
    func nodes(forAlbum album: AlbumEntity) async throws -> [NodeEntity]
}

public final class AlbumContentsUseCase <T: AlbumContentsUpdateNotifierRepositoryProtocol, U: MediaUseCaseProtocol, V: FileSearchRepositoryProtocol>: AlbumContentsUseCaseProtocol {
    private var albumContentsRepo: T
    private let mediaUseCase: U
    private let fileSearchRepo: V
    
    public let updatePublisher: AnyPublisher<Void, Never>
    private let updateSubject = PassthroughSubject<Void, Never>()
    
    public init(albumContentsRepo: T, mediaUseCase: U, fileSearchRepo: V) {
        self.albumContentsRepo = albumContentsRepo
        self.mediaUseCase = mediaUseCase
        self.fileSearchRepo = fileSearchRepo
        
        updatePublisher = AnyPublisher(updateSubject)
        
        self.albumContentsRepo.onAlbumReload = { [weak self] in
            self?.updateSubject.send()
        }
    }
    
    // MARK: Protocols
    
    public func nodes(forAlbum album: AlbumEntity) async throws -> [NodeEntity] {
        async let allPhotos = try await fileSearchRepo.allPhotos()
        if (album.type == .favourite) {
            async let allVideos = try fileSearchRepo.allVideos()
            return try await [allPhotos, allVideos]
                .flatMap { $0 }
                .filter { $0.hasThumbnail && $0.isFavourite }
        } else {
            return filter(photos: try await allPhotos, forAlbum: album)
        }
    }
    
    // MARK: Private
    
    private func filter(photos: [NodeEntity], forAlbum album: AlbumEntity) -> [NodeEntity] {
        var nodes = [NodeEntity]()
        if album.type == .raw {
            nodes = photos.filter { $0.hasThumbnail && mediaUseCase.isRawImage($0.name) }
        } else if album.type == .gif {
            nodes = photos.filter { $0.hasThumbnail && mediaUseCase.isGifImage($0.name) }
        }
        return nodes
    }
}
