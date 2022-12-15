import Combine
import MEGADomain

final class AlbumContentsUseCase <T: AlbumContentsUpdateNotifierRepositoryProtocol, U: FavouriteNodesRepositoryProtocol, V: PhotoLibraryUseCaseProtocol, W: MediaUseCaseProtocol, X: FileSearchRepositoryProtocol>: AlbumContentsUseCaseProtocol {
    private var albumContentsRepo: T
    private var favouriteRepo: U
    private var photoUseCase: V
    private var mediaUseCase: W
    private let fileSearchRepo: X
    
    let updatePublisher: AnyPublisher<Void, Never>
    private let updateSubject = PassthroughSubject<Void, Never>()
    
    init(albumContentsRepo: T, favouriteRepo: U, photoUseCase: V, mediaUseCase: W, fileSearchRepo: X) {
        self.albumContentsRepo = albumContentsRepo
        self.favouriteRepo = favouriteRepo
        self.photoUseCase = photoUseCase
        self.mediaUseCase = mediaUseCase
        self.fileSearchRepo = fileSearchRepo
        
        updatePublisher = AnyPublisher(updateSubject)
        
        self.albumContentsRepo.onAlbumReload = { [weak self] in
            self?.updateSubject.send()
        }
    }
    
    // MARK: Protocols
    
    func favouriteAlbumNodes() async throws -> [NodeEntity] {
        async let nodes = try favouriteRepo.allFavouritesNodes()
        let container = await photoUseCase.photoLibraryContainer()
        
        var filteredNodes = try await nodes.filter {
            self.isNodeInContainer($0, container: container) && $0.name.mnz_isVisualMediaPathExtension && $0.hasThumbnail
        }
        
        filteredNodes.sort { $0.modificationTime >= $1.modificationTime }
        
        return filteredNodes
    }
    
    func nodes(forAlbum album: AlbumEntity) async throws -> [NodeEntity] {
        async let allPhotos = try await fileSearchRepo.allPhotos()
        if (album.type == .favourite) {
            async let allVideos = try fileSearchRepo.allVideos()
            return try await [allPhotos, allVideos]
                .flatMap { $0 }
                .filter { $0.hasThumbnail && $0.isFavourite }
        } else {
            let allThumbnailPhotos = try await allPhotos.filter { $0.hasThumbnail }
            return filter(photos: allThumbnailPhotos, forAlbum: album)
        }
    }
    
    // MARK: Private
    private func isNodeInContainer(_ node: NodeEntity, container: PhotoLibraryContainerEntity) -> Bool {
        let nameUrl = URL(fileURLWithPath: node.name)
        let isImage = mediaUseCase.isImage(for: nameUrl)
        let isVideo = mediaUseCase.isVideo(for: nameUrl)
        return isImage || (isVideo && node.parentHandle == container.cameraUploadNode?.handle || node.parentHandle == container.mediaUploadNode?.handle)
    }
    
    private func filter(photos: [NodeEntity], forAlbum album: AlbumEntity) -> [NodeEntity] {
        var nodes = [NodeEntity]()
        if album.type == .raw {
            nodes = photos.filter { mediaUseCase.isRawImage($0.name) }
        } else if album.type == .gif {
            nodes = photos.filter { mediaUseCase.isGifImage($0.name) }
        }
        return nodes
    }
}
