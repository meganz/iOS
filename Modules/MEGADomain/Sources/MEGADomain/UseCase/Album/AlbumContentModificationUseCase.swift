import Combine

public protocol AlbumContentModificationUseCaseProtocol {
    func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity
    func rename(album id: HandleEntity, with newName: String) async throws -> String
    func deletePhotos(in albumId: HandleEntity, photos: [AlbumPhotoEntity]) async throws -> AlbumElementsResultEntity
    func updateAlbumCover(album id: HandleEntity, withNode nodeId: HandleEntity) async throws -> HandleEntity
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
    
    public func deletePhotos(in albumId: HandleEntity, photos: [AlbumPhotoEntity]) async throws -> AlbumElementsResultEntity {
        let photoIds = photos.compactMap(\.albumPhotoId)
        guard photoIds.isNotEmpty else {
            return AlbumElementsResultEntity(success: 0, failure: 0)
        }
        return try await userAlbumRepo.deleteAlbumElements(albumId: albumId, elementIds: photoIds)
    }
    
    public func updateAlbumCover(album id: HandleEntity, withNode nodeId: HandleEntity) async throws -> HandleEntity {
        let content = await userAlbumRepo.albumContent(by: id, includeElementsInRubbishBin: false)
        
        guard let coverId = content.first(where: { $0.nodeId == nodeId })?.id else { return .invalid }
        
        let _ = try await userAlbumRepo.updateAlbumCover(for: id, elementId: coverId)
        return nodeId
    }
}
