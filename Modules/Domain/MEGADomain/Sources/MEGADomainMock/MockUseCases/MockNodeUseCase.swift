import MEGADomain
import MEGASwift

public final class MockNodeUseCase: NodeUseCaseProtocol, @unchecked Sendable {
    
    public enum Invocation: Sendable, Equatable {
        case isDownloaded
    }
    
    @Atomic public var invocations: [Invocation] = []
    
    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        AsyncStream { continuation in
            continuation.yield(with: .success([]))
        }
        .eraseToAnyAsyncSequence()
    }
    
    private let isDownloaded: Bool
    private let isNodeInRubbishBin: Bool
    private let nodeAccessLevel: NodeAccessTypeEntity
    private let nodes: [HandleEntity: NodeEntity]
    private let folderLinkInfo: FolderLinkInfoEntity?
    private let nodeForFileLink: NodeEntity?
    private let nodeInRubbishBin: NodeEntity?
    
    public init(
        isDownloaded: Bool = false,
        isNodeInRubbishBin: Bool = false,
        nodes: [HandleEntity: NodeEntity] = [:],
        nodeAccessLevel: NodeAccessTypeEntity = .unknown,
        folderLinkInfo: FolderLinkInfoEntity? = nil,
        nodeForFileLink: NodeEntity? = nil,
        nodeInRubbishBin: NodeEntity? = nil
    ) {
        self.isDownloaded = isDownloaded
        self.isNodeInRubbishBin = isNodeInRubbishBin
        self.nodes = nodes
        self.nodeAccessLevel = nodeAccessLevel
        self.folderLinkInfo = folderLinkInfo
        self.nodeForFileLink = nodeForFileLink
        self.nodeInRubbishBin = nodeInRubbishBin
    }
    
    public func rootNode() -> NodeEntity? {
        nil
    }
    
    public func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity {
        nodeAccessLevel
    }
    
    public func nodeAccessLevelAsync(nodeHandle: HandleEntity) async -> NodeAccessTypeEntity {
        nodeAccessLevel
    }
    
    public func labelString(label: NodeLabelTypeEntity) -> String {
        label.labelString
    }
    
    public func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int) {
        (0, 0)
    }
    
    public func sizeFor(node: NodeEntity) -> UInt64? {
        nil
    }
    
    public func folderInfo(node: NodeEntity) async throws -> FolderInfoEntity? {
        nil
    }
    
    public func folderLinkInfo(_ folderLink: String) async throws -> FolderLinkInfoEntity? {
        folderLinkInfo
    }
    
    public func hasVersions(nodeHandle: HandleEntity) -> Bool {
        false
    }
    
    public func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        $invocations.mutate { $0.append(.isDownloaded) }
        return isDownloaded
    }
    
    public func isARubbishBinRootNode(nodeHandle: HandleEntity) -> Bool {
        false
    }
    
    public func isInRubbishBin(nodeHandle: HandleEntity) -> Bool {
        isNodeInRubbishBin
    }
    
    public func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        nodes[handle]
    }
    
    public func nodeForFileLink(_ fileLink: FileLinkEntity) async -> NodeEntity? {
        nodeForFileLink
    }
    
    public func nodeForHandle(_ handle: HandleEntity) async -> NodeEntity? {
        nodes[handle]
    }
    
    public func parentForHandle(_ handle: HandleEntity) -> NodeEntity? {
        guard let parentHandle = nodes[handle]?.parentHandle else { return nil }
        return nodes[parentHandle]
    }
    
    public func parentsForHandle(_ handle: HandleEntity) async -> [NodeEntity]? {
        guard let parentHandle = nodes[handle]?.parentHandle, let parentNode = nodes[parentHandle] else { return nil }
        return [parentNode]
    }
    
    public func asyncChildrenOf(node: NodeEntity, sortOrder: SortOrderEntity) async -> NodeListEntity? {
        nil
    }
    
    public func childrenOf(node: NodeEntity) -> NodeListEntity? {
        nil
    }
    
    public func childrenNamesOf(node: NodeEntity) -> [String]? {
        nil
    }
    
    public func isRubbishBinRoot(node: NodeEntity) -> Bool {
        false
    }
    
    public func isRestorable(node: NodeEntity) -> Bool {
        nodeInRubbishBin?.handle == node.handle
    }
    
    public func createFolder(with name: String, in parent: NodeEntity) async throws -> NodeEntity {
        throw GenericErrorEntity()
    }
}
