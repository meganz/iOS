public protocol FilesSearchUseCaseProtocol {
    func search(string: String?,
                parent node: NodeEntity?,
                recursive: Bool,
                supportCancel: Bool,
                sortOrderType: SortOrderEntity,
                cancelPreviousSearchIfNeeded: Bool,
                completion: @escaping ([NodeEntity]?, Bool) -> Void)
    
    func search(string: String?,
                parent node: NodeEntity?,
                recursive: Bool,
                supportCancel: Bool,
                sortOrderType: SortOrderEntity,
                formatType: NodeFormatEntity,
                cancelPreviousSearchIfNeeded: Bool) async throws -> [NodeEntity]
    
    func onNodesUpdate(with nodesUpdateHandler: @escaping ([NodeEntity]) -> Void)
}

public final class FilesSearchUseCase: FilesSearchUseCaseProtocol {
    private let repo: any FilesSearchRepositoryProtocol
    private let nodeFormat: NodeFormatEntity
    private var nodesUpdateListenerRepo: any NodesUpdateListenerProtocol
    private var nodesUpdateHandler: (([NodeEntity]) -> Void)?
    
    public init(
        repo: any FilesSearchRepositoryProtocol,
        nodeFormat: NodeFormatEntity,
        nodesUpdateListenerRepo: any NodesUpdateListenerProtocol
    ) {
        self.repo = repo
        self.nodeFormat = nodeFormat
        self.nodesUpdateListenerRepo = nodesUpdateListenerRepo
        
        addNodesUpdateHandler()
    }
    
    public func search(
        string: String?,
        parent node: NodeEntity?,
        recursive: Bool,
        supportCancel: Bool,
        sortOrderType: SortOrderEntity,
        cancelPreviousSearchIfNeeded: Bool,
        completion: @escaping ([NodeEntity]?, Bool) -> Void
    ) {
        if cancelPreviousSearchIfNeeded {
            repo.cancelSearch()
        }
        
        repo.search(string: string,
                    parent: node,
                    recursive: recursive,
                    supportCancel: supportCancel,
                    sortOrderType: sortOrderType,
                    formatType: nodeFormat,
                    completion: completion)
    }
    
    public func search(
        string: String?,
        parent node: NodeEntity?,
        recursive: Bool,
        supportCancel: Bool,
        sortOrderType: SortOrderEntity,
        formatType: NodeFormatEntity,
        cancelPreviousSearchIfNeeded: Bool
    ) async throws -> [NodeEntity] {
        
        if cancelPreviousSearchIfNeeded {
            repo.cancelSearch()
        }
        
        return try await repo.search(
            string: string,
            parent: node,
            recursive: recursive,
            supportCancel: supportCancel,
            sortOrderType: sortOrderType,
            formatType: formatType
        )
    }
    
    public func onNodesUpdate(with nodesUpdateHandler: @escaping ([NodeEntity]) -> Void) {
        self.nodesUpdateHandler = nodesUpdateHandler
    }
    
    // MARK: - Private
    
    private func addNodesUpdateHandler() {
        self.nodesUpdateListenerRepo.onNodesUpdateHandler = { [weak self] nodes in
            guard let self else { return }
            self.nodesUpdateHandler?(nodes)
        }
    }
}
