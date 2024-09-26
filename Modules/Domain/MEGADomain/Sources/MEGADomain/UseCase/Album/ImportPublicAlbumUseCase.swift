import Foundation

public protocol ImportPublicAlbumUseCaseProtocol: Sendable {
    /// Import public photos into album
    ///
    /// Create a folder with the album name in parent folder. The photos will be copied to the new folder
    /// then the copied photos will be used  to create an album.
    ///
    /// - Parameter name: name of the album and folder
    /// - Parameter photos: public photos to copy
    /// - Parameter parentFolder: folder to create album folder in
    /// - Throws: `CreateFolderErrorEntity`, `NodeErrorEntity`, `CopyOrMoveErrorEntity` or `AlbumErrorEntity`.
    func importAlbum(name: String, photos: [NodeEntity], parentFolder: NodeEntity) async throws
}

public struct ImportPublicAlbumUseCase<T: SaveCollectionToFolderUseCaseProtocol,
                                       U: UserAlbumRepositoryProtocol>: ImportPublicAlbumUseCaseProtocol {
    private let saveCollectionToFolderUseCase: T
    private let userAlbumRepository: U
    
    public init(saveCollectionToFolderUseCase: T,
                userAlbumRepository: U) {
        self.saveCollectionToFolderUseCase = saveCollectionToFolderUseCase
        self.userAlbumRepository = userAlbumRepository
    }
    
    public func importAlbum(name: String, photos: [NodeEntity], parentFolder: NodeEntity) async throws {
        let copiedNodes = try await saveCollectionToFolderUseCase.saveToFolder(collectionName: name,
                                                                           nodes: photos,
                                                                           parent: parentFolder)
        try Task.checkCancellation()
        let album = try await userAlbumRepository.createAlbum(name)
        try Task.checkCancellation()
        _ = try await userAlbumRepository.addPhotosToAlbum(by: album.id.handle,
                                                           nodes: copiedNodes)
    }
}
