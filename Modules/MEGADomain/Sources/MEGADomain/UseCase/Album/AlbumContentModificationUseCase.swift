import Combine

public protocol AlbumContentModificationUseCaseProtocol {
    func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity
    func rename(album id: HandleEntity, with newName: String) async throws -> String
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
    
    public func rename(album id: HandleEntity, with newName: String) async throws -> String {
        try await userAlbumRepo.updateAlbumName(newName, id)
    }
}
