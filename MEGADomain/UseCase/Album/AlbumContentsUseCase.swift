import Combine

protocol AlbumContentsUseCaseProtocol {
    var updatePublisher: AnyPublisher<Void, Never> { get }
    
    func favouriteAlbumNodes() async throws -> [NodeEntity]
}

final class AlbumContentsUseCase <T: AlbumContentsUpdateNotifierRepositoryProtocol, U: FavouriteNodesRepositoryProtocol, V: PhotoLibraryUseCaseProtocol>: AlbumContentsUseCaseProtocol {
    private var albumContentsRepo: T
    private var favouriteRepo: U
    private var photoUseCase: V
    
    let updatePublisher: AnyPublisher<Void, Never>
    private let updateSubject = PassthroughSubject<Void, Never>()
    
    init(albumContentsRepo: T, favouriteRepo: U, photoUseCase: V) {
        self.albumContentsRepo = albumContentsRepo
        self.favouriteRepo = favouriteRepo
        self.photoUseCase = photoUseCase
        
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
        node.isImage || (node.isVideo && node.parentHandle == container.cameraUploadNode?.handle || node.parentHandle == container.mediaUploadNode?.handle)
    }
}
