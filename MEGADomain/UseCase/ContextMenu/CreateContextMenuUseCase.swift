
protocol CreateContextMenuUseCaseProtocol {
    func createContextMenu(config: CMConfigEntity) -> CMEntity?
}

struct CreateContextMenuUseCase: CreateContextMenuUseCaseProtocol {
    private let repo: CreateContextMenuRepositoryProtocol
    
    init(repo: CreateContextMenuRepositoryProtocol) {
        self.repo = repo
    }
    
    func createContextMenu(config: CMConfigEntity) -> CMEntity? {
        repo.createContextMenu(config: config)
    }
}
