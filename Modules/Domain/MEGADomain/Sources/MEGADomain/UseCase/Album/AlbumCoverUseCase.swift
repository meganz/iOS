import Foundation

public protocol AlbumCoverUseCaseProtocol: Sendable {
    
    /// Determine the album cover of the album based of the album cover state and contents
    /// - Parameters:
    ///   - album: Album to retrieve cover for
    ///   - photos: Album photo and video contents
    /// - Returns: Album cover node or nil if cover could not be determined
    func albumCover(for album: AlbumEntity, photos: [AlbumPhotoEntity]) async -> NodeEntity?
}

public struct AlbumCoverUseCase: AlbumCoverUseCaseProtocol {
    private let nodeRepository: any NodeRepositoryProtocol
    
    public init(nodeRepository: some NodeRepositoryProtocol) {
        self.nodeRepository = nodeRepository
    }
    
    public func albumCover(for album: AlbumEntity, photos: [AlbumPhotoEntity]) async -> NodeEntity? {
        if let albumCover = album.coverNode,
           !nodeRepository.isInRubbishBin(node: albumCover),
           photos.contains(where: { $0.photo == albumCover }) {
            albumCover
        } else if let latestPhoto = photos.latestModifiedPhoto() {
            latestPhoto
        } else {
            nil
        }
    }
}
