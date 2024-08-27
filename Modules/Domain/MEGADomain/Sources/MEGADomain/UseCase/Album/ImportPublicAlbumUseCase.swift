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

public struct ImportPublicAlbumUseCase<T: SaveAlbumToFolderUseCaseProtocol,
                                       U: UserAlbumRepositoryProtocol>: ImportPublicAlbumUseCaseProtocol {
    private let saveAlbumToFolderUseCase: T
    private let userAlbumRepository: U
    
    public init(saveAlbumToFolderUseCase: T,
                userAlbumRepository: U) {
        self.saveAlbumToFolderUseCase = saveAlbumToFolderUseCase
        self.userAlbumRepository = userAlbumRepository
    }
    
    public func importAlbum(name: String, photos: [NodeEntity], parentFolder: NodeEntity) async throws {
        let copiedPhotos = try await saveAlbumToFolderUseCase.saveToFolder(albumName: name,
                                                                           photos: photos,
                                                                           parent: parentFolder)
        try Task.checkCancellation()
        let album = try await userAlbumRepository.createAlbum(name)
        try Task.checkCancellation()
        _ = try await userAlbumRepository.addPhotosToAlbum(by: album.id,
                                                           nodes: copiedPhotos)
    }
}
