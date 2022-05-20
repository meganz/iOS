import Combine

protocol AlbumContentsUpdateNotifierUseCase {
    var updatePublisher: AnyPublisher<Void, Never> { get }
}

final class AlbumContentsUseCase <T: AlbumContentsUpdateNotifierRepositoryProtocol>: AlbumContentsUpdateNotifierUseCase {
    private var albumContentsRepo: T
    
    let updatePublisher: AnyPublisher<Void, Never>
    private let updateSubject = PassthroughSubject<Void, Never>()
    
    init(
        albumContentsRepo: T
    ) {
        self.albumContentsRepo = albumContentsRepo
        
        updatePublisher = AnyPublisher(updateSubject)
        self.albumContentsRepo.onAlbumReload = { [weak self] in
            self?.updateSubject.send()
        }
    }
}
