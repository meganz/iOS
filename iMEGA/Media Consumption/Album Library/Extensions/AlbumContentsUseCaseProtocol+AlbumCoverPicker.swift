import MEGADomain

extension AlbumContentsUseCaseProtocol {
    
    func latestModifiedPhotos(in album: AlbumEntity) async throws -> [AlbumPhotoEntity] {
        var nodes = try await photos(in: album)
        nodes.sort {
            if $0.photo.modificationTime == $1.photo.modificationTime {
                $0.photo.handle > $1.photo.handle
            } else {
                $0.photo.modificationTime > $1.photo.modificationTime
            }
        }
        return nodes
    }
    
    func selectCoverNode(photos: [AlbumPhotoEntity], album: AlbumEntity) async -> AlbumPhotoEntity? {
        if let coverNode = album.coverNode,
           let coverPhoto = photos.first(where: { $0.id == coverNode.handle }) {
            return coverPhoto
        } else {
            return photos.first
        }
    }
}
