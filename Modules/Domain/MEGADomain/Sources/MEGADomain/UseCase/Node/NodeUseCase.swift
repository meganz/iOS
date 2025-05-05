import AsyncAlgorithms
import MEGASwift
// MARK: - Use case protocol -
public protocol NodeUseCaseProtocol: Sendable {
    /// Node updates
    /// - Returns: `AnyAsyncSequence` that will yield `[NodeEntity]` items until sequence terminated.
    var nodeUpdates: AnyAsyncSequence<[NodeEntity]> { get }
    func rootNode() -> NodeEntity?
    func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity
    func nodeAccessLevelAsync(nodeHandle: HandleEntity) async -> NodeAccessTypeEntity
    func labelString(label: NodeLabelTypeEntity) -> String
    func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int)
    func sizeFor(node: NodeEntity) -> UInt64?
    func folderInfo(node: NodeEntity) async throws -> FolderInfoEntity?
    func folderLinkInfo(_ folderLink: String) async throws -> FolderLinkInfoEntity?
    func hasVersions(nodeHandle: HandleEntity) -> Bool
    func isDownloaded(nodeHandle: HandleEntity) -> Bool
    func isARubbishBinRootNode(nodeHandle: HandleEntity) -> Bool
    func isInRubbishBin(nodeHandle: HandleEntity) -> Bool
    /// This will be deprecated soon, please use async version instead to avoid app hang due to sdkMutex.
    func nodeForHandle(_ handle: HandleEntity) -> NodeEntity?
    func nodeForHandle(_ handle: HandleEntity) async -> NodeEntity?
    func nodeForFileLink(_ fileLink: FileLinkEntity) async throws -> NodeEntity?
    func parentForHandle(_ handle: HandleEntity) -> NodeEntity?
    func parentsForHandle(_ handle: HandleEntity) async -> [NodeEntity]?
    func asyncChildrenOf(node: NodeEntity, sortOrder: SortOrderEntity) async -> NodeListEntity?
    func childrenOf(node: NodeEntity) -> NodeListEntity?
    func childrenNamesOf(node: NodeEntity) -> [String]?
    func isRubbishBinRoot(node: NodeEntity) -> Bool
    func isRestorable(node: NodeEntity) -> Bool
    func createFolder(with name: String, in parent: NodeEntity) async throws -> NodeEntity
    func isFileTakenDown(_ nodeHandle: HandleEntity) async -> Bool
}

// MARK: - Use case implementation -
public struct NodeUseCase<T: NodeDataRepositoryProtocol, U: NodeValidationRepositoryProtocol, V: NodeRepositoryProtocol>: NodeUseCaseProtocol {
    
    private let nodeDataRepository: T
    private let nodeValidationRepository: U
    private let nodeRepository: V
    
    public init(nodeDataRepository: T, nodeValidationRepository: U, nodeRepository: V) {
        self.nodeDataRepository = nodeDataRepository
        self.nodeValidationRepository = nodeValidationRepository
        self.nodeRepository = nodeRepository
    }
    
    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        nodeRepository.nodeUpdates
    }
    
    public func rootNode() -> NodeEntity? {
        nodeRepository.rootNode()
    }

    public func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity {
        nodeDataRepository.nodeAccessLevel(nodeHandle: nodeHandle)
    }
    
    public func nodeAccessLevelAsync(nodeHandle: HandleEntity) async -> NodeAccessTypeEntity {
        await nodeDataRepository.nodeAccessLevelAsync(nodeHandle: nodeHandle)
    }
    
    public func labelString(label: NodeLabelTypeEntity) -> String {
        return nodeDataRepository.labelString(label: label)
    }
    
    public func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int) {
        nodeDataRepository.getFilesAndFolders(nodeHandle: nodeHandle)
    }
    
    public func sizeFor(node: NodeEntity) -> UInt64? {
        nodeDataRepository.sizeForNode(handle: node.handle)
    }
    
    public func folderInfo(node: NodeEntity) async throws -> FolderInfoEntity? {
        try await nodeDataRepository.folderInfo(node: node)
    }
    
    public func folderLinkInfo(_ folderLink: String) async throws -> FolderLinkInfoEntity? {
        try await nodeDataRepository.folderLinkInfo(folderLink)
    }
    
    public func hasVersions(nodeHandle: HandleEntity) -> Bool {
        nodeValidationRepository.hasVersions(nodeHandle: nodeHandle)
    }
    
    public func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        nodeValidationRepository.isDownloaded(nodeHandle: nodeHandle)
    }

    public func isARubbishBinRootNode(nodeHandle: HandleEntity) -> Bool {
        nodeRepository.rubbishNode()?.handle == nodeHandle
    }

    public func isInRubbishBin(nodeHandle: HandleEntity) -> Bool {
        nodeValidationRepository.isInRubbishBin(nodeHandle: nodeHandle)
    }
    
    public func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        nodeDataRepository.nodeForHandle(handle)
    }

    public func nodeForHandle(_ handle: HandleEntity) async -> NodeEntity? {
        await nodeDataRepository.nodeForHandle(handle)
    }
    
    public func nodeForFileLink(_ fileLink: FileLinkEntity) async throws -> NodeEntity? {
        try await nodeRepository.nodeFor(fileLink: fileLink)
    }
    
    public func parentForHandle(_ handle: HandleEntity) -> NodeEntity? {
        nodeDataRepository.parentForHandle(handle)
    }
    
    public func parentsForHandle(_ handle: HandleEntity) async -> [NodeEntity]? {
        guard let node = await nodeForHandle(handle) else { return nil }
        return await nodeRepository.parents(of: node)
    }
    
    public func childrenNamesOf(node: NodeEntity) -> [String]? {
        nodeRepository.childrenNames(of: node)
    }
    
    public func isRubbishBinRoot(node: NodeEntity) -> Bool {
        node.handle == nodeRepository.rubbishNode()?.handle
    }
 
    public func isRestorable(node: NodeEntity) -> Bool {
        isInRubbishBin(nodeHandle: node.handle)
    }
    
    public func asyncChildrenOf(node: NodeEntity, sortOrder: SortOrderEntity) async -> NodeListEntity? {
        await nodeRepository.asyncChildren(of: node, sortOrder: sortOrder)
    }
    
    public func childrenOf(node: NodeEntity) -> NodeListEntity? {
        nodeRepository.children(of: node)
    }

    public func createFolder(with name: String, in parent: NodeEntity) async throws -> NodeEntity {
        try await nodeRepository.createFolder(with: name, in: parent)
    }
    
    public func isFileTakenDown(_ nodeHandle: HandleEntity) async -> Bool {
        guard let node = await nodeForHandle(nodeHandle) else { return false }
        return node.isFile && node.isTakenDown
    }
}
