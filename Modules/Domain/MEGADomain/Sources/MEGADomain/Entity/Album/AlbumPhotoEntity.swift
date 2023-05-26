import Foundation

public struct AlbumPhotoEntity: Hashable, Sendable {
    public let photo: NodeEntity
    public let albumPhotoId: HandleEntity?
   
    public init(photo: NodeEntity,
                albumPhotoId: HandleEntity? = nil) {
        self.photo = photo
        self.albumPhotoId = albumPhotoId
    }
}

extension AlbumPhotoEntity: Identifiable {
    public var id: HandleEntity { photo.handle }
}
