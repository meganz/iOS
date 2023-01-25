import MEGADomain

protocol FilesSearchUseCaseProtocol {
    func search(string: String?,
                inNode node: NodeEntity?,
                sortOrderType: SortOrderEntity,
                cancelPreviousSearchIfNeeded: Bool,
                completionBlock: @escaping ([NodeEntity]?, Bool) -> Void)
    func onNodesUpdate(with nodesUpdateHandler: @escaping ([NodeEntity]) -> Void)
}

final class FilesSearchUseCase: FilesSearchUseCaseProtocol {
    private let repo: FilesSearchRepositoryProtocol
    private let explorerType: ExplorerTypeEntity
    private let nodesUpdateListenerRepo: SDKNodesUpdateListenerRepository
    private var nodesUpdateHandler: (([NodeEntity]) -> Void)?
    
    init(repo: FilesSearchRepositoryProtocol,
         explorerType: ExplorerTypeEntity,
         nodesUpdateListenerRepo: SDKNodesUpdateListenerRepository) {
        self.repo = repo
        self.explorerType = explorerType
        self.nodesUpdateListenerRepo = nodesUpdateListenerRepo
        
        addNodesUpdateHandler()
    }
    
    func search(string: String?,
                inNode node: NodeEntity?,
                sortOrderType: SortOrderEntity,
                cancelPreviousSearchIfNeeded: Bool,
                completionBlock: @escaping ([NodeEntity]?, Bool) -> Void) {
        let formatType = explorerType.toNodeFormatEntity()
        
        if cancelPreviousSearchIfNeeded {
            repo.cancelSearch()
        }
        
        repo.search(string: string,
                    parent: node,
                    sortOrderType: sortOrderType,
                    formatType: formatType,
                    completion: completionBlock)
    }
    
    func onNodesUpdate(with nodesUpdateHandler: @escaping ([NodeEntity]) -> Void) {
        self.nodesUpdateHandler = nodesUpdateHandler
    }
    
    // MARK: - Private
    
    private func addNodesUpdateHandler() {
        self.nodesUpdateListenerRepo.onUpdateHandler = { [weak self] nodes in
            guard let self = self else { return }
            self.nodesUpdateHandler?(nodes.toNodeEntities())
        }
    }
}
