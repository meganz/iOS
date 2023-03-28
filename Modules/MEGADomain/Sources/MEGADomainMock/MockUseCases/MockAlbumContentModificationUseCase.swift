import Foundation
import MEGADomain

public final class MockAlbumModificationUseCase: AlbumModificationUseCaseProtocol {
    private var resultEntity = AlbumElementsResultEntity(success: 0, failure: 0)
    
    public private(set) var addedPhotosToAlbum: [NodeEntity]?
    public private(set) var deletedPhotos: [AlbumPhotoEntity]?
    public private(set) var deletedAlbumsIds: [HandleEntity]?
    
    private let albums: [AlbumEntity]
    
    public init(resultEntity: AlbumElementsResultEntity? = nil, albums: [AlbumEntity] = []) {
        if let resultEntity = resultEntity {
            self.resultEntity = resultEntity
        }
        self.albums = albums
    }

    public func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity {
        addedPhotosToAlbum = nodes
        return resultEntity
    }
    
    public func rename(album id: HandleEntity, with newName: String) async throws -> String {
        return newName
    }
    
    public func updateAlbumCover(album id: HandleEntity, withAlbumPhoto albumPhoto: AlbumPhotoEntity) async throws -> HandleEntity {
        return albumPhoto.id
    }

    public func deletePhotos(in albumId: HandleEntity, photos: [AlbumPhotoEntity]) async throws -> AlbumElementsResultEntity {
        deletedPhotos = photos
        return resultEntity
    }
    
    public func delete(albums ids: [HandleEntity]) async -> [HandleEntity] {
        deletedAlbumsIds = ids
        return albums.map { $0.id }
    }
}
