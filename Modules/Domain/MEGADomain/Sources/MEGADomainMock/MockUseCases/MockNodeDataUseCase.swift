import AsyncAlgorithms
import MEGADomain
import MEGASwift

public final class MockNodeDataUseCase: NodeUseCaseProtocol, @unchecked Sendable {
    
    private let nodeAccessLevelVariable: NodeAccessTypeEntity
    private let filesAndFolders: (Int, Int)
    private let folderInfo: FolderInfoEntity?
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
    private let isInheritingSensitivityResult: Result<Bool, Error>
    private let isInheritingSensitivityResults: [HandleEntity: Result<Bool, Error>]
    private let monitorInheritedSensitivityForNode: AnyAsyncThrowingSequence<Bool, any Error>
    private let sensitivityChangesForNode: AnyAsyncSequence<Bool>
    private let _rootNode: NodeEntity?

    public var labelStringToReturn: Atomic<String>
    public var isMultimediaFileNode_CalledTimes = 0
    
    public init(nodeAccessLevelVariable: NodeAccessTypeEntity = .unknown,
                labelString: String = "",
                filesAndFolders: (Int, Int) = (0, 0),
                folderInfo: FolderInfoEntity? = nil,
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
                isInheritingSensitivityResult: Result<Bool, Error> = .failure(GenericErrorEntity()),
                isInheritingSensitivityResults: [HandleEntity: Result<Bool, Error>] = [:],
                monitorInheritedSensitivityForNode: AnyAsyncThrowingSequence<Bool, any Error> = EmptyAsyncSequence().eraseToAnyAsyncThrowingSequence(),
                sensitivityChangesForNode: AnyAsyncSequence<Bool> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
                rootNode: NodeEntity? = nil
    ) {
        self.nodeAccessLevelVariable = nodeAccessLevelVariable
        labelStringToReturn = Atomic(wrappedValue: labelString)
        self.filesAndFolders = filesAndFolders
        self.folderInfo = folderInfo
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
        self.isInheritingSensitivityResult = isInheritingSensitivityResult
        self.isInheritingSensitivityResults = isInheritingSensitivityResults
        self.monitorInheritedSensitivityForNode = monitorInheritedSensitivityForNode
        self.sensitivityChangesForNode = sensitivityChangesForNode
        self._rootNode = rootNode
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
    
    public func isInheritingSensitivity(node: NodeEntity) async throws -> Bool {
        try await withCheckedThrowingContinuation {
            $0.resume(with: isInheritingSensitivityResult(for: node))
        }
    }
    
    public func isInheritingSensitivity(node: NodeEntity) throws -> Bool {
        switch isInheritingSensitivityResult(for: node) {
        case .success(let isSensitive):
           isSensitive
        case .failure(let error):
            throw error
        }
    }
    
    public func monitorInheritedSensitivity(for node: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {
        monitorInheritedSensitivityForNode
    }
    
    public func sensitivityChanges(for node: NodeEntity) -> AnyAsyncSequence<Bool> {
        sensitivityChangesForNode
    }
    
    // MARK: - Private Helpers
    
    private func isInheritingSensitivityResult(for node: NodeEntity) -> Result<Bool, Error> {
        isInheritingSensitivityResults[node.handle] ?? isInheritingSensitivityResult
    }

    public func mergeInheritedAndDirectSensitivityChanges(for node: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {
        merge(
            sensitivityChanges(for: node),
            monitorInheritedSensitivity(for: node)
        ).eraseToAnyAsyncThrowingSequence()
    }
}
