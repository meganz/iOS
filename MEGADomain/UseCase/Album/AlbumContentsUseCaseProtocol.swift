import Combine

protocol AlbumContentsUseCaseProtocol {
    var updatePublisher: AnyPublisher<Void, Never> { get }
    
    func favouriteAlbumNodes() async throws -> [NodeEntity]
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
    
    func favouriteAlbumNodes() async throws -> [NodeEntity] {
        try await favouriteRepo.allFavouritesNodes()
    }
}
