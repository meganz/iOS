
protocol FilesSearchUseCaseProtocol {
    func search(string: String?,
                inNode node: MEGANode?,
                sortOrderType: MEGASortOrderType,
                cancelPreviousSearchIfNeeded: Bool,
                completionBlock: @escaping ([MEGANode]?, Bool) -> Void)
    func onNodesUpdate(with nodesUpdateHandler: @escaping ([MEGANode]) -> Void)
}

final class FilesSearchUseCase: FilesSearchUseCaseProtocol {
    private let repo: FilesSearchRepositoryProtocol
    private let explorerType: ExplorerTypeEntity
    private let nodesUpdateListenerRepo: SDKNodesUpdateListenerRepository
    private var nodesUpdateHandler: (([MEGANode]) -> Void)?
    
    init(repo: FilesSearchRepositoryProtocol,
         explorerType: ExplorerTypeEntity,
         nodesUpdateListenerRepo: SDKNodesUpdateListenerRepository) {
        self.repo = repo
        self.explorerType = explorerType
        self.nodesUpdateListenerRepo = nodesUpdateListenerRepo
        
        addNodesUpdateHandler()
    }
    
    func search(string: String?,
                inNode node: MEGANode?,
                sortOrderType: MEGASortOrderType,
                cancelPreviousSearchIfNeeded: Bool,
                completionBlock: @escaping ([MEGANode]?, Bool) -> Void) {
        let formatType = repo.megaNodeFormatType(from: explorerType)
        
        if cancelPreviousSearchIfNeeded {
            repo.cancelSearch()
        }
        
        repo.search(string: string,
                    inNode: node,
                    sortOrderType: sortOrderType,
                    formatType: formatType,
                    completionBlock: completionBlock)
        
    }
    
    func onNodesUpdate(with nodesUpdateHandler: @escaping ([MEGANode]) -> Void) {
        self.nodesUpdateHandler = nodesUpdateHandler
    }
    
    // MARK: - Private
    
    private func addNodesUpdateHandler() {
        self.nodesUpdateListenerRepo.onUpdateHandler = { [weak self] nodes in
            guard let self = self else { return }
            self.nodesUpdateHandler?(nodes)
        }
    }
}
