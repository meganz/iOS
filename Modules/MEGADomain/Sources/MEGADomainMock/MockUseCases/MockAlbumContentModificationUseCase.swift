import Foundation
import MEGADomain

public final class MockAlbumContentModificationUseCase: AlbumContentModificationUseCaseProtocol {
    private var resultEntity = AlbumElementsResultEntity(success: 0, failure: 0)
    
    public private(set) var addedPhotosToAlbum: [NodeEntity]?
    public private(set) var deletedPhotos: [AlbumPhotoEntity]?
    
    public init(resultEntity: AlbumElementsResultEntity? = nil) {
        if let resultEntity = resultEntity {
            self.resultEntity = resultEntity
        }
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
}
