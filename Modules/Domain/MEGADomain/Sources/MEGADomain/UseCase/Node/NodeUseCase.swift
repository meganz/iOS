// MARK: - Use case protocol -
public protocol NodeUseCaseProtocol {
    func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity
    func nodeAccessLevelAsync(nodeHandle: HandleEntity) async -> NodeAccessTypeEntity
    func labelString(label: NodeLabelTypeEntity) -> String
    func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int)
    func hasVersions(nodeHandle: HandleEntity) -> Bool
    func isDownloaded(nodeHandle: HandleEntity) -> Bool
    func isInRubbishBin(nodeHandle: HandleEntity) -> Bool
}

// MARK: - Use case implementation -
public struct NodeUseCase<T: NodeDataRepositoryProtocol, U: NodeValidationRepositoryProtocol>: NodeUseCaseProtocol {
    
    private let nodeDataRepository: T
    private let nodeValidationRepository: U
    
    public init(nodeDataRepository: T, nodeValidationRepository: U) {
        self.nodeDataRepository = nodeDataRepository
        self.nodeValidationRepository = nodeValidationRepository
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
}
