import Combine

public protocol AlbumModificationUseCaseProtocol: Sendable {
    func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity
    func rename(album id: HandleEntity, with newName: String) async throws -> String
    func updateAlbumCover(album id: HandleEntity, withAlbumPhoto albumPhoto: AlbumPhotoEntity) async throws -> HandleEntity
    func deletePhotos(in albumId: HandleEntity, photos: [AlbumPhotoEntity]) async throws -> AlbumElementsResultEntity
    func delete(albums ids: [HandleEntity]) async -> [HandleEntity]
}

public struct AlbumModificationUseCase: AlbumModificationUseCaseProtocol {
    private let userAlbumRepo: any UserAlbumRepositoryProtocol

    public init(userAlbumRepo: any UserAlbumRepositoryProtocol) {
        self.userAlbumRepo = userAlbumRepo
    }
    
    // MARK: Protocols
    
    public func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity {
        try await userAlbumRepo.addPhotosToAlbum(by: id, nodes: nodes)
    }
    
    public func rename(album id: HandleEntity, with newName: String) async throws -> String {
        try await userAlbumRepo.updateAlbumName(newName, id)
    }
    
    public func updateAlbumCover(album id: HandleEntity, withAlbumPhoto albumPhoto: AlbumPhotoEntity) async throws -> HandleEntity {
        guard let albumPhotoId = albumPhoto.albumPhotoId else { throw AlbumPhotoErrorEntity.photoIdDoesNotExist }
        return try await userAlbumRepo.updateAlbumCover(for: id, elementId: albumPhotoId)
    }

    public func deletePhotos(in albumId: HandleEntity, photos: [AlbumPhotoEntity]) async throws -> AlbumElementsResultEntity {
        let photoIds = photos.compactMap(\.albumPhotoId)
        guard photoIds.isNotEmpty else {
            return AlbumElementsResultEntity(success: 0, failure: 0)
        }
        return try await userAlbumRepo.deleteAlbumElements(albumId: albumId, elementIds: photoIds)
    }
    
    public func delete(albums ids: [HandleEntity]) async -> [HandleEntity] {
        await withTaskGroup(of: HandleEntity?.self) { group in
            guard group.isCancelled == false else {
                return []
            }
            
            ids.forEach { albumId in
                group.addTask {
                    try? await userAlbumRepo.deleteAlbum(by: albumId)
                }
            }
            
            return await group.reduce(into: [HandleEntity](), {
                if let id = $1 { $0.append(id) }
            })
        }
    }
}
