import Combine
import MEGADomain

protocol AlbumContentsUseCaseProtocol {
    var updatePublisher: AnyPublisher<Void, Never> { get }
    
    func favouriteAlbumNodes() async throws -> [NodeEntity]
}

final class AlbumContentsUseCase <T: AlbumContentsUpdateNotifierRepositoryProtocol, U: FavouriteNodesRepositoryProtocol, V: PhotoLibraryUseCaseProtocol, W: MediaUseCaseProtocol>: AlbumContentsUseCaseProtocol {
    private var albumContentsRepo: T
    private var favouriteRepo: U
    private var photoUseCase: V
    private var mediaUseCase: W
    
    let updatePublisher: AnyPublisher<Void, Never>
    private let updateSubject = PassthroughSubject<Void, Never>()
    
    init(albumContentsRepo: T, favouriteRepo: U, photoUseCase: V, mediaUseCase: W) {
        self.albumContentsRepo = albumContentsRepo
        self.favouriteRepo = favouriteRepo
        self.photoUseCase = photoUseCase
        self.mediaUseCase = mediaUseCase
        
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
            self.isNodeInContainer($0, container: container) && $0.name.mnz_isVisualMediaPathExtension
        }
        
        filteredNodes.sort { $0.modificationTime >= $1.modificationTime }
        
        return filteredNodes
    }
    
    // MARK: Private
    private func isNodeInContainer(_ node: NodeEntity, container: PhotoLibraryContainerEntity) -> Bool {
        let nameUrl = URL(fileURLWithPath: node.name)
        let isImage = mediaUseCase.isImage(for: nameUrl)
        let isVideo = mediaUseCase.isVideo(for: nameUrl)
        return isImage || (isVideo && node.parentHandle == container.cameraUploadNode?.handle || node.parentHandle == container.mediaUploadNode?.handle)
    }
}
