import MEGADomain

// MARK: - Use case protocol -
protocol NodeActionUseCaseProtocol {
    func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity
    func labelString(label: NodeLabelTypeEntity) -> String
    func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int)
    func hasVersions(nodeHandle: HandleEntity) -> Bool
    func isDownloaded(nodeHandle: HandleEntity) -> Bool
    func isInRubbishBin(nodeHandle: HandleEntity) -> Bool
    func slideShowImages(for node: NodeEntity) -> [NodeEntity]
}

// MARK: - Use case implementation -
struct NodeActionUseCase<T: NodeRepositoryProtocol>: NodeActionUseCaseProtocol {
    
    private let nodeRepository: T
    
    init(repo: T) {
        self.nodeRepository = repo
    }
    
    func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity {
        nodeRepository.nodeAccessLevel(nodeHandle: nodeHandle)
    }
    
    func labelString(label: NodeLabelTypeEntity) -> String {
        return nodeRepository.labelString(label: label)
    }
    
    func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int) {
        nodeRepository.getFilesAndFolders(nodeHandle: nodeHandle)
    }
    
    func hasVersions(nodeHandle: HandleEntity) -> Bool {
        nodeRepository.hasVersions(nodeHandle: nodeHandle)
    }
    
    func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        nodeRepository.isDownloaded(nodeHandle: nodeHandle)
    }
    
    func isInRubbishBin(nodeHandle: HandleEntity) -> Bool {
        nodeRepository.isInRubbishBin(nodeHandle: nodeHandle)
    }

    func slideShowImages(for node: NodeEntity) -> [NodeEntity] {
        let parentHandle = node.isFolder ? node.handle : node.parentHandle
        
        return nodeRepository.images(for: parentHandle)
    }
}
