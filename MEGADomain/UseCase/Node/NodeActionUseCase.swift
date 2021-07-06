// MARK: - Use case protocol -
protocol NodeActionUseCaseProtocol {
    func nodeAccessLevel(nodeHandle: MEGAHandle) -> NodeAccessTypeEntity
    func downloadToOffline(nodeHandle: MEGAHandle)
}

// MARK: - Use case implementation -
struct NodeActionUseCase: NodeActionUseCaseProtocol {
    private let repo: NodeActionRepositoryProtocol
    
    init(repo: NodeActionRepositoryProtocol) {
        self.repo = repo
    }
    
    func nodeAccessLevel(nodeHandle: MEGAHandle) -> NodeAccessTypeEntity {
        repo.nodeAccessLevel(nodeHandle: nodeHandle)
    }
    
    func downloadToOffline(nodeHandle: MEGAHandle) {
        repo.downloadToOffline(nodeHandle: nodeHandle)
    }
}
