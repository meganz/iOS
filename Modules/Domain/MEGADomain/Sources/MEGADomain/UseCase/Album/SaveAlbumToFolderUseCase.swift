import Foundation

public protocol SaveAlbumToFolderUseCaseProtocol: Sendable {
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
                                       U: ShareAlbumRepositoryProtocol,
                                       V: NodeRepositoryProtocol>: SaveAlbumToFolderUseCaseProtocol {
    private let nodeActionRepository: T
    private let shareAlbumRepository: U
    private let nodeRepository: V
    
    public init(nodeActionRepository: T,
                shareAlbumRepository: U,
                nodeRepository: V) {
        self.nodeActionRepository = nodeActionRepository
        self.shareAlbumRepository = shareAlbumRepository
        self.nodeRepository = nodeRepository
    }
    
    public func saveToFolder(albumName: String,
                             photos: [NodeEntity],
                             parent: NodeEntity) async throws -> [NodeEntity] {
        let albumFolderName = await folderName(in: parent, albumName: albumName)
        try Task.checkCancellation()
        let albumFolder = try await nodeActionRepository.createFolder(name: albumFolderName,
                                                                      parent: parent)
        try Task.checkCancellation()
        return try await shareAlbumRepository.copyPublicPhotos(toFolder: albumFolder,
                                                               photos: photos)
    }
    
    // MARK: - Private
    private func folderName(in parent: NodeEntity, albumName: String) async -> String {
        var folderName = albumName
        while await nodeRepository.childNode(parent: parent, name: folderName, type: .folder) != nil {
            folderName += " (1)"
        }
        return folderName
    }
}
