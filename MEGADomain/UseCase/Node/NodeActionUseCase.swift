// MARK: - Use case protocol -
protocol NodeActionUseCaseProtocol {
    func nodeAccessLevel(nodeHandle: MEGAHandle) -> NodeAccessTypeEntity
    func labelString(label: NodeLabelTypeEntity) -> String
    func getFilesAndFolders(nodeHandle: MEGAHandle) -> (childFileCount: Int, childFolderCount: Int)
    func hasVersions(nodeHandle: MEGAHandle) -> Bool
    func isDownloaded(nodeHandle: MEGAHandle) -> Bool
    func isInRubbishBin(nodeHandle: MEGAHandle) -> Bool
    func slideShowImages(for node: NodeEntity) -> [NodeEntity]
}

// MARK: - Use case implementation -
struct NodeActionUseCase<T: NodeRepositoryProtocol>: NodeActionUseCaseProtocol {
    
    private let nodeRepository: T
    
    init(repo: T) {
        self.nodeRepository = repo
    }
    
    func nodeAccessLevel(nodeHandle: MEGAHandle) -> NodeAccessTypeEntity {
        nodeRepository.nodeAccessLevel(nodeHandle: nodeHandle)
    }
    
    func labelString(label: NodeLabelTypeEntity) -> String {
        return nodeRepository.labelString(label: label)
    }
    
    func getFilesAndFolders(nodeHandle: MEGAHandle) -> (childFileCount: Int, childFolderCount: Int) {
        nodeRepository.getFilesAndFolders(nodeHandle: nodeHandle)
    }
    
    func hasVersions(nodeHandle: MEGAHandle) -> Bool {
        nodeRepository.hasVersions(nodeHandle: nodeHandle)
    }
    
    func isDownloaded(nodeHandle: MEGAHandle) -> Bool {
        nodeRepository.isDownloaded(nodeHandle: nodeHandle)
    }
    
    func isInRubbishBin(nodeHandle: MEGAHandle) -> Bool {
        nodeRepository.isInRubbishBin(nodeHandle: nodeHandle)
    }

    func slideShowImages(for node: NodeEntity) -> [NodeEntity] {
        let parentHandle = node.isFolder ? node.handle : node.parentHandle
        
        return nodeRepository.images(for: parentHandle)
    }
}
