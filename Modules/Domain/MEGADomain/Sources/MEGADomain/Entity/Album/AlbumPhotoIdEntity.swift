public struct AlbumPhotoIdEntity: Hashable, Sendable {
    public let albumId: HandleEntity
    public let albumPhotoId: HandleEntity
    public let nodeId: HandleEntity
    
    public init(albumId: HandleEntity,
                albumPhotoId: HandleEntity,
                nodeId: HandleEntity) {
        self.albumId = albumId
        self.albumPhotoId = albumPhotoId
        self.nodeId = nodeId
    }
}

extension AlbumPhotoIdEntity: Identifiable {
    public var id: HandleEntity { albumPhotoId }
}
