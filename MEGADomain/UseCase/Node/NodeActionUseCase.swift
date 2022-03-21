// MARK: - Use case protocol -
protocol NodeActionUseCaseProtocol {
    func nodeAccessLevel() -> NodeAccessTypeEntity
    func downloadToOffline()
    func labelString(label: NodeLabelTypeEntity) -> String
    func getFilesAndFolders() -> (childFileCount: Int, childFolderCount: Int)
    func hasVersions() -> Bool
    func isDownloaded() -> Bool
    func isInRubbishBin() -> Bool
}

// MARK: - Use case implementation -
struct NodeActionUseCase<T: NodeActionRepositoryProtocol>: NodeActionUseCaseProtocol {
    private let repo: T
    
    init(repo: T) {
        self.repo = repo
    }
    
    func nodeAccessLevel() -> NodeAccessTypeEntity {
        repo.nodeAccessLevel()
    }
    
    func downloadToOffline() {
        repo.downloadToOffline()
    }
    
    func labelString(label: NodeLabelTypeEntity) -> String {
        return repo.labelString(label: label)
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
    
    func isInRubbishBin() -> Bool {
        repo.isInRubbishBin()
    }
}
