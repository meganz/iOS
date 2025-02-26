import AsyncAlgorithms
import MEGADomain
import MEGASwift

public final class MockNodeDataUseCase: NodeUseCaseProtocol, @unchecked Sendable {
    private let nodeAccessLevelVariable: NodeAccessTypeEntity
    private let filesAndFolders: (Int, Int)
    private let folderInfo: FolderInfoEntity?
    private let folderLinkInfo: FolderLinkInfoEntity?
    private let size: UInt64
    public var versions: Bool
    public var downloadedToReturn: Bool
    public var isARubbishBinRootNodeValue: Bool
    public var isNodeInRubbishBin: (HandleEntity) -> Bool
    public var nodes: [NodeEntity]
    private var nodeEntity: NodeEntity?
    private let nodeListEntity: NodeListEntity?
    private let createFolderResult: Result<NodeEntity, NodeCreationErrorEntity>
    private let isNodeRestorable: Bool
    private let _rootNode: NodeEntity?
    private let nodeUpdateAsyncSequence: AnyAsyncSequence<[NodeEntity]>

    public var labelStringToReturn: Atomic<String>
    public var isMultimediaFileNode_CalledTimes = 0
    
    public init(nodeAccessLevelVariable: NodeAccessTypeEntity = .unknown,
                labelString: String = "",
                filesAndFolders: (Int, Int) = (0, 0),
                folderInfo: FolderInfoEntity? = nil,
                folderLinkInfo: FolderLinkInfoEntity? = nil,
                size: UInt64 = UInt64(0),
                versions: Bool = false,
                downloaded: Bool = false,
                isARubbishBinRootNodeValue: Bool = false,
                nodes: [NodeEntity] = [],
                node: NodeEntity? = nil,
                nodeListEntity: NodeListEntity? = nil,
                createFolderResult: Result<NodeEntity, NodeCreationErrorEntity> = .success(.init()),
                isNodeInRubbishBin: @escaping (HandleEntity) -> Bool = { _ in false },
                isNodeRestorable: Bool = false,
                rootNode: NodeEntity? = nil,
                nodeUpdateAsyncSequence: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.nodeAccessLevelVariable = nodeAccessLevelVariable
        labelStringToReturn = Atomic(wrappedValue: labelString)
        self.filesAndFolders = filesAndFolders
        self.folderInfo = folderInfo
        self.folderLinkInfo = folderLinkInfo
        self.size = size
        self.versions = versions
        self.downloadedToReturn = downloaded
        self.isARubbishBinRootNodeValue = isARubbishBinRootNodeValue
        self.nodes = nodes
        self.nodeEntity = node
        self.nodeListEntity = nodeListEntity
        self.createFolderResult = createFolderResult
        self.isNodeInRubbishBin = isNodeInRubbishBin
        self.isNodeRestorable = isNodeRestorable
        self._rootNode = rootNode
        self.nodeUpdateAsyncSequence = nodeUpdateAsyncSequence
    }
    
    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        nodeUpdateAsyncSequence
    }
    
    public func rootNode() -> NodeEntity? {
        _rootNode
    }
    
    public func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity {
        return nodeAccessLevelVariable
    }
    
    public func nodeAccessLevelAsync(nodeHandle: HandleEntity) async -> NodeAccessTypeEntity {
        nodeAccessLevelVariable
    }
    
    public func downloadToOffline(nodeHandle: HandleEntity) { }
    
    public func labelString(label: NodeLabelTypeEntity) -> String {
        labelStringToReturn.wrappedValue
    }
    
    public func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int) {
        filesAndFolders
    }
    
    public func sizeFor(node: NodeEntity) -> UInt64? {
        size
    }
    
    public func folderInfo(node: NodeEntity) async throws -> FolderInfoEntity? {
        folderInfo
    }
    
    public func folderLinkInfo(_ folderLink: String) async throws -> FolderLinkInfoEntity? {
        folderLinkInfo
    }
    
    public func hasVersions(nodeHandle: HandleEntity) -> Bool {
        versions
    }
    
    public func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        downloadedToReturn
    }

    public func isARubbishBinRootNode(nodeHandle: MEGADomain.HandleEntity) -> Bool {
        isARubbishBinRootNodeValue
    }

    public func isInRubbishBin(nodeHandle: HandleEntity) -> Bool {
        isNodeInRubbishBin(nodeHandle)
    }
    
    public func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        nodes.first {
            $0.handle == handle
        }
    }
    
    public func nodeForFileLink(_ fileLink: FileLinkEntity) async -> NodeEntity? {
        nodeEntity
    }
    
    public func parentForHandle(_ handle: HandleEntity) -> NodeEntity? {
        nodeEntity
    }
    
    public func parentsForHandle(_ handle: HandleEntity) async -> [NodeEntity]? {
        nil
    }
    
    public func childrenNamesOf(node: MEGADomain.NodeEntity) -> [String]? {
        nil
    }
    
    public func isRubbishBinRoot(node: MEGADomain.NodeEntity) -> Bool {
        false
    }
    
    public func isRestorable(node: MEGADomain.NodeEntity) -> Bool {
        isNodeRestorable
    }

    public func asyncChildrenOf(node: NodeEntity, sortOrder: SortOrderEntity) async -> NodeListEntity? {
        nil
    }

    public func childrenOf(node: NodeEntity) -> NodeListEntity? {
        nodeListEntity
    }

    public func createFolder(with name: String, in parent: NodeEntity) async throws -> NodeEntity {
        try createFolderResult.get()
    }
}
