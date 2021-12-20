// MARK: - Use case protocol -
protocol NodeActionUseCaseProtocol {
    func nodeAccessLevel() -> NodeAccessTypeEntity
    func downloadToOffline()
    func labelString(label: NodeLabelTypeModel) -> String
    func getFilesAndFolders() -> (childFileCount: Int, childFolderCount: Int)
    func hasVersions() -> Bool
    func isDownloaded() -> Bool
}

// MARK: - Use case implementation -
struct NodeActionUseCase: NodeActionUseCaseProtocol {
    private let repo: NodeActionRepositoryProtocol
    
    init(repo: NodeActionRepositoryProtocol) {
        self.repo = repo
    }
    
    func nodeAccessLevel() -> NodeAccessTypeEntity {
        repo.nodeAccessLevel()
    }
    
    func downloadToOffline() {
        repo.downloadToOffline()
    }
    
    func labelString(label: NodeLabelTypeModel) -> String {
        let nodeLabelTypeEntity = label.toNodeLabelTypeEntity()
        return repo.labelString(label: nodeLabelTypeEntity)
    }
    
    func getFilesAndFolders() -> (childFileCount: Int, childFolderCount: Int) {
        repo.getFilesAndFolders()
    }
    
    func hasVersions() -> Bool {
        repo.hasVersions()
    }
    
    func isDownloaded() -> Bool {
        repo.isDownloaded()
    }
}
