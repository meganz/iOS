import Foundation

public struct AlbumPhotoEntity: Hashable, Sendable {
    public let photo: NodeEntity
    public let albumPhotoId: HandleEntity?
    public let isSensitiveInherited: Bool?
   
    public init(photo: NodeEntity,
                albumPhotoId: HandleEntity? = nil,
                isSensitiveInherited: Bool? = nil) {
        self.photo = photo
        self.albumPhotoId = albumPhotoId
        self.isSensitiveInherited = isSensitiveInherited
    }
}

extension AlbumPhotoEntity: Identifiable {
    public var id: HandleEntity { photo.handle }
}
