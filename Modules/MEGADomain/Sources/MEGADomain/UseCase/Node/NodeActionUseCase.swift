// MARK: - Use case protocol -
public protocol NodeActionUseCaseProtocol {
    func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity
    func labelString(label: NodeLabelTypeEntity) -> String
    func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int)
    func hasVersions(nodeHandle: HandleEntity) -> Bool
    func isDownloaded(nodeHandle: HandleEntity) -> Bool
    func isInRubbishBin(nodeHandle: HandleEntity) -> Bool
}

// MARK: - Use case implementation -
public struct NodeActionUseCase<T: NodeRepositoryProtocol>: NodeActionUseCaseProtocol {
    
    private let nodeRepository: T
    
    public init(repo: T) {
        self.nodeRepository = repo
    }
    
    public func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity {
        nodeRepository.nodeAccessLevel(nodeHandle: nodeHandle)
    }
    
    public func labelString(label: NodeLabelTypeEntity) -> String {
        return nodeRepository.labelString(label: label)
    }
    
    public func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int) {
        nodeRepository.getFilesAndFolders(nodeHandle: nodeHandle)
    }
    
    public func hasVersions(nodeHandle: HandleEntity) -> Bool {
        nodeRepository.hasVersions(nodeHandle: nodeHandle)
    }
    
    public func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        nodeRepository.isDownloaded(nodeHandle: nodeHandle)
    }
    
    public func isInRubbishBin(nodeHandle: HandleEntity) -> Bool {
        nodeRepository.isInRubbishBin(nodeHandle: nodeHandle)
    }
}
