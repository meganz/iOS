import Foundation

public protocol SaveCollectionToFolderUseCaseProtocol: Sendable {
    /// Create subfolder (using collection name) in parent folder and copy the public photos / videos
    /// into it.
    /// - Parameter collectionName: collection (album or video playlist) name that be used as the folder name
    /// - Parameter nodes: public photos or videos to copy
    /// - Parameter parent: folder to create collection (album or video playlist) folder in
    /// - Returns: Copied photo or video nodes from collection (album or video playlist) folder
    /// - Throws: `CreateFolderErrorEntity`, `NodeErrorEntity` or `CopyOrMoveErrorEntity`.
    func saveToFolder(collectionName: String,
                      nodes: [NodeEntity],
                      parent: NodeEntity) async throws -> [NodeEntity]
}

public struct SaveCollectionToFolderUseCase<T: NodeActionRepositoryProtocol,
                                       U: ShareCollectionRepositoryProtocol,
                                       V: NodeRepositoryProtocol>: SaveCollectionToFolderUseCaseProtocol {
    private let nodeActionRepository: T
    private let shareCollectionRepository: U
    private let nodeRepository: V
    
    public init(nodeActionRepository: T,
                shareCollectionRepository: U,
                nodeRepository: V) {
        self.nodeActionRepository = nodeActionRepository
        self.shareCollectionRepository = shareCollectionRepository
        self.nodeRepository = nodeRepository
    }
    
    public func saveToFolder(collectionName: String,
                             nodes: [NodeEntity],
                             parent: NodeEntity) async throws -> [NodeEntity] {
        let collectionFolderName = await folderName(in: parent, collectionName: collectionName)
        try Task.checkCancellation()
        let collectionFolder = try await nodeActionRepository.createFolder(name: collectionFolderName,
                                                                      parent: parent)
        try Task.checkCancellation()
        return try await shareCollectionRepository.copyPublicNodes(toFolder: collectionFolder,
                                                               nodes: nodes)
    }
    
    // MARK: - Private
    private func folderName(in parent: NodeEntity, collectionName: String) async -> String {
        var folderName = collectionName
        while await nodeRepository.childNode(parent: parent, name: folderName, type: .folder) != nil {
            folderName += " (1)"
        }
        return folderName
    }
}
