import MEGASwift

public protocol FilesSearchUseCaseProtocol {
    
    /// Listen to node updates through an async sequence.
    /// Returns: Stream of updated node entities.
    var nodeUpdates: AnyAsyncSequence<[NodeEntity]> { get }
    
    /// Search files and folders by name. It will return a list of nodes based on the criteria provided in the params.
    /// - Parameters:
    ///   - filter: SearchFilterEntity contains all necessary information to build search query.
    ///   - cancelPreviousSearchIfNeeded: Indicates if the previous search should be cancelled before starting a new one.
    ///   - completion: Completion block to handle result from the request
    func search(filter: SearchFilterEntity, cancelPreviousSearchIfNeeded: Bool, completion: @escaping ([NodeEntity]?, Bool) -> Void)
    
    /// Search files and folders by name. It will return a list of nodes based on the criteria provided in the params.
    /// - Parameters:
    ///   - filter: SearchFilterEntity contains all necessary information to build search query.
    ///   - cancelPreviousSearchIfNeeded: Indicates if the previous search should be cancelled before starting a new one.
    /// - Returns: List of NodeEntities that match the criteria provided.
    func search(filter: SearchFilterEntity, cancelPreviousSearchIfNeeded: Bool) async throws -> [NodeEntity]
    
    /// Search files and folders by name. It will return a list of nodes based on the criteria provided in the params.
    /// - Parameters:
    ///   - filter: SearchFilterEntity contains all necessary information to build search query.
    ///   - cancelPreviousSearchIfNeeded: Indicates if the previous search should be cancelled before starting a new one.
    /// - Returns: NodeListEntity that matches the criteria provided.
    func search(filter: SearchFilterEntity, cancelPreviousSearchIfNeeded: Bool) async throws -> NodeListEntity
    
    /// This function is deprecated and we should begin to use:
    /// -  `func search(string: String?, parent node: NodeEntity?, recursive: Bool, sensitiveIncluded: Bool, supportCancel: Bool, sortOrderType: SortOrderEntity, formatType: NodeFormatEntity, cancelPreviousSearchIfNeeded: Bool, completion: @escaping ([NodeEntity]?, Bool) -> Void)`
    func search(string: String?,
                parent node: NodeEntity?,
                recursive: Bool,
                supportCancel: Bool,
                sortOrderType: SortOrderEntity,
                cancelPreviousSearchIfNeeded: Bool,
                completion: @escaping ([NodeEntity]?, Bool) -> Void)
    
    /// This function is deprecated and we should begin to use:
    /// -  `func search(string: String?, parent node: NodeEntity?, recursive: Bool, sensitiveIncluded: Bool, supportCancel: Bool, sortOrderType: SortOrderEntity, formatType: NodeFormatEntity, cancelPreviousSearchIfNeeded: Bool) async throws -> [NodeEntity]`
    func search(string: String?,
                parent node: NodeEntity?,
                recursive: Bool,
                supportCancel: Bool,
                sortOrderType: SortOrderEntity,
                formatType: NodeFormatEntity,
                cancelPreviousSearchIfNeeded: Bool) async throws -> [NodeEntity]
    
    func onNodesUpdate(with nodesUpdateHandler: @escaping ([NodeEntity]) -> Void)
    func stopNodesUpdateListener()
    func startNodesUpdateListener()
}

public final class FilesSearchUseCase: FilesSearchUseCaseProtocol {

    private let repo: any FilesSearchRepositoryProtocol
    private let nodeFormat: NodeFormatEntity
    private var nodesUpdateListenerRepo: any NodesUpdateListenerProtocol
    private var nodesUpdateHandler: (([NodeEntity]) -> Void)?
    private let nodeRepository: any NodeRepositoryProtocol
    
    public init(
        repo: any FilesSearchRepositoryProtocol,
        nodeFormat: NodeFormatEntity,
        nodesUpdateListenerRepo: any NodesUpdateListenerProtocol,
        nodeRepository: any NodeRepositoryProtocol
    ) {
        self.repo = repo
        self.nodeFormat = nodeFormat
        self.nodesUpdateListenerRepo = nodesUpdateListenerRepo
        self.nodeRepository = nodeRepository
        
        addNodesUpdateHandler()
    }
    
    public func search(filter: SearchFilterEntity, cancelPreviousSearchIfNeeded: Bool, completion: @escaping ([NodeEntity]?, Bool) -> Void) {
        if cancelPreviousSearchIfNeeded {
            repo.cancelSearch()
        }
        
        repo.search(filter: filter, completion: completion)
    }
    
    public func search(filter: SearchFilterEntity, cancelPreviousSearchIfNeeded: Bool) async throws -> NodeListEntity {
        if cancelPreviousSearchIfNeeded {
            repo.cancelSearch()
        }
        
        return try await repo.search(filter: filter)
    }
    
    public func search(filter: SearchFilterEntity, cancelPreviousSearchIfNeeded: Bool) async throws -> [NodeEntity] {
        if cancelPreviousSearchIfNeeded {
            repo.cancelSearch()
        }
        return try await repo.search(filter: filter)
    }
            
    public func onNodesUpdate(with nodesUpdateHandler: @escaping ([NodeEntity]) -> Void) {
        self.nodesUpdateHandler = nodesUpdateHandler
    }
    
    public func stopNodesUpdateListener() {
        self.nodesUpdateHandler = nil
        self.nodesUpdateListenerRepo.onNodesUpdateHandler = nil
    }
    
    public func startNodesUpdateListener() {
        if nodesUpdateHandler == nil {
            addNodesUpdateHandler()
        }
    }
    
    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        nodeRepository.nodeUpdates
    }
    
    // MARK: - Private
    
    private func addNodesUpdateHandler() {
        self.nodesUpdateListenerRepo.onNodesUpdateHandler = { [weak self] nodes in
            guard let self else { return }
            self.nodesUpdateHandler?(nodes)
        }
    }
}

// MARK: - Deprecated searchApi usage
extension FilesSearchUseCase {
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
}
