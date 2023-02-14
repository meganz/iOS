public protocol FilesSearchUseCaseProtocol {
    func search(string: String?,
                parent node: NodeEntity?,
                supportCancel: Bool,
                sortOrderType: SortOrderEntity,
                cancelPreviousSearchIfNeeded: Bool,
                completion: @escaping ([NodeEntity]?, Bool) -> Void)
    func onNodesUpdate(with nodesUpdateHandler: @escaping ([NodeEntity]) -> Void)
}

public final class FilesSearchUseCase: FilesSearchUseCaseProtocol {
    private let repo: FilesSearchRepositoryProtocol
    private let nodeFormat: NodeFormatEntity
    private var nodesUpdateListenerRepo: NodesUpdateListenerProtocol
    private var nodesUpdateHandler: (([NodeEntity]) -> Void)?
    
    public init(repo: FilesSearchRepositoryProtocol,
         nodeFormat: NodeFormatEntity,
         nodesUpdateListenerRepo: NodesUpdateListenerProtocol) {
        self.repo = repo
        self.nodeFormat = nodeFormat
        self.nodesUpdateListenerRepo = nodesUpdateListenerRepo
        
        addNodesUpdateHandler()
    }
    
    public func search(string: String?,
                parent node: NodeEntity?,
                supportCancel: Bool,
                sortOrderType: SortOrderEntity,
                cancelPreviousSearchIfNeeded: Bool,
                completion: @escaping ([NodeEntity]?, Bool) -> Void) {
        if cancelPreviousSearchIfNeeded {
            repo.cancelSearch()
        }
        
        repo.search(string: string,
                    parent: node,
                    supportCancel: supportCancel,
                    sortOrderType: sortOrderType,
                    formatType: nodeFormat,
                    completion: completion)
    }
    
    public func onNodesUpdate(with nodesUpdateHandler: @escaping ([NodeEntity]) -> Void) {
        self.nodesUpdateHandler = nodesUpdateHandler
    }
    
    // MARK: - Private
    
    private func addNodesUpdateHandler() {
        self.nodesUpdateListenerRepo.onNodesUpdateHandler = { [weak self] nodes in
            guard let self = self else { return }
            self.nodesUpdateHandler?(nodes)
        }
    }
}
