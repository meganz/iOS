import Foundation

public protocol SaveAlbumToFolderUseCaseProtocol {
    /// Create subfolder (using album name) in parent folder and copy the public photos
    /// into it.
    /// - Parameter albumName: album name that be used as the folder name
    /// - Parameter photos: public photos to copy
    /// - Parameter parent: folder to create album folder in
    /// - Returns: Copied photo nodes from album folder
    /// - Throws: `CreateFolderErrorEntity`, `NodeErrorEntity` or `CopyOrMoveErrorEntity`.
    func saveToFolder(albumName: String,
                      photos: [NodeEntity],
                      parent: NodeEntity) async throws -> [NodeEntity]
}

public struct SaveAlbumToFolderUseCase<T: NodeActionRepositoryProtocol,
                                       U: ShareAlbumRepositoryProtocol>: SaveAlbumToFolderUseCaseProtocol {
    private let nodeActionRepository: T
    private let shareAlbumRepository: U
    
    public init(nodeActionRepository: T,
                shareAlbumRepository: U) {
        self.nodeActionRepository = nodeActionRepository
        self.shareAlbumRepository = shareAlbumRepository
    }
    
    public func saveToFolder(albumName: String,
                             photos: [NodeEntity],
                             parent: NodeEntity) async throws -> [NodeEntity] {
        let album = try await nodeActionRepository.createFolder(name: albumName, parent: parent)
        try Task.checkCancellation()
        return try await shareAlbumRepository.copyPublicPhotos(toFolder: album, photos: photos)
    }
}
