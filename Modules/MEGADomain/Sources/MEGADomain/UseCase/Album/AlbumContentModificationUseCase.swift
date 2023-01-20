import Combine

public protocol AlbumContentModificationUseCaseProtocol {
    func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity
}

public final class AlbumContentModificationUseCase: AlbumContentModificationUseCaseProtocol {
    private let userAlbumRepo: UserAlbumRepositoryProtocol

    public init(userAlbumRepo: UserAlbumRepositoryProtocol) {
        self.userAlbumRepo = userAlbumRepo
    }
    
    // MARK: Protocols
    
    public func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity {
        try await userAlbumRepo.addPhotosToAlbum(by: id, nodes: nodes)
    }
}
