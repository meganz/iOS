import Combine

protocol AlbumContentsUseCaseProtocol {
    var updatePublisher: AnyPublisher<Void, Never> { get }
    
    func favouriteAlbumNodes(withCameraUploadNode node: NodeEntity?) async throws -> [NodeEntity]
}

final class AlbumContentsUseCase <T: AlbumContentsUpdateNotifierRepositoryProtocol, U: FavouriteNodesRepositoryProtocol>: AlbumContentsUseCaseProtocol {
    private var albumContentsRepo: T
    private var favouriteRepo: U
    
    let updatePublisher: AnyPublisher<Void, Never>
    private let updateSubject = PassthroughSubject<Void, Never>()
    
    init(albumContentsRepo: T, favouriteRepo: U) {
        self.albumContentsRepo = albumContentsRepo
        self.favouriteRepo = favouriteRepo
        
        updatePublisher = AnyPublisher(updateSubject)
        
        self.albumContentsRepo.onAlbumReload = { [weak self] in
            self?.updateSubject.send()
        }
    }
    
    // MARK: Protocols
    
    func favouriteAlbumNodes(withCameraUploadNode node: NodeEntity?) async throws -> [NodeEntity] {
        var nodes = try await favouriteRepo.allFavouritesNodes()
        
        nodes = nodes.filter({
            return $0.isImage || ($0.isVideo && $0.parentHandle == node?.handle)
        })
        
        nodes = nodes.sorted { $0.modificationTime >= $1.modificationTime }
        
        return nodes
    }
}
