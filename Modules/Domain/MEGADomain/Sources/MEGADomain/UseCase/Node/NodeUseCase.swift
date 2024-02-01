// MARK: - Use case protocol -
public protocol NodeUseCaseProtocol {
    func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity
    func nodeAccessLevelAsync(nodeHandle: HandleEntity) async -> NodeAccessTypeEntity
    func labelString(label: NodeLabelTypeEntity) -> String
    func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int)
    func hasVersions(nodeHandle: HandleEntity) -> Bool
    func isDownloaded(nodeHandle: HandleEntity) -> Bool
    func isInRubbishBin(nodeHandle: HandleEntity) -> Bool
    func nodeForHandle(_ handle: HandleEntity) -> NodeEntity?
    func parentForHandle(_ handle: HandleEntity) -> NodeEntity?
    func parentsForHandle(_ handle: HandleEntity) async -> [NodeEntity]?
    func childrenOf(node: NodeEntity) async -> NodeListEntity?
    func childrenNamesOf(node: NodeEntity) -> [String]?
    func isRubbishBinRoot(node: NodeEntity) -> Bool
    func isRestorable(node: NodeEntity) -> Bool
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
    
    public func hasVersions(nodeHandle: HandleEntity) -> Bool {
        nodeValidationRepository.hasVersions(nodeHandle: nodeHandle)
    }
    
    public func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        nodeValidationRepository.isDownloaded(nodeHandle: nodeHandle)
    }
    
    public func isInRubbishBin(nodeHandle: HandleEntity) -> Bool {
        nodeValidationRepository.isInRubbishBin(nodeHandle: nodeHandle)
    }
    
    public func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        nodeDataRepository.nodeForHandle(handle)
    }
    
    public func parentForHandle(_ handle: HandleEntity) -> NodeEntity? {
        nodeDataRepository.parentForHandle(handle)
    }
    
    public func parentsForHandle(_ handle: HandleEntity) async -> [NodeEntity]? {
        guard let node = nodeForHandle(handle) else { return nil }
        return await nodeRepository.parents(of: node)
    }
    
    public func childrenNamesOf(node: NodeEntity) -> [String]? {
        nodeRepository.childrenNames(of: node)
    }
    
    public func isRubbishBinRoot(node: NodeEntity) -> Bool {
        node.handle == nodeRepository.rubbishNode()?.handle
    }
 
    public func isRestorable(node: NodeEntity) -> Bool {
        let restoreParentHandle = node.restoreParentHandle
        guard let restoreNode = nodeRepository.nodeForHandle(restoreParentHandle) else {
            return false
        }
        
        return !isInRubbishBin(nodeHandle: restoreNode.handle) && isInRubbishBin(nodeHandle: node.handle)
    }
    
    public func childrenOf(node: NodeEntity) async -> NodeListEntity? {
       await nodeRepository.children(of: node)
    }
}
