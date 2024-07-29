import MEGASwift

public protocol FilesSearchUseCaseProtocol: Sendable {
    
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
    ///   - page: SearchPageEntity contains details for retrieving a paged result for the search query.
    ///   - cancelPreviousSearchIfNeeded: Indicates if the previous search should be cancelled before starting a new one.
    /// - Returns: List of NodeEntities that match the criteria provided.
    func search(filter: SearchFilterEntity, page: SearchPageEntity, cancelPreviousSearchIfNeeded: Bool) async throws -> [NodeEntity]
    
    /// Search files and folders by name. It will return a list of nodes based on the criteria provided in the params.
    /// - Parameters:
    ///   - filter: SearchFilterEntity contains all necessary information to build search query.
    ///   - cancelPreviousSearchIfNeeded: Indicates if the previous search should be cancelled before starting a new one.
    /// - Returns: NodeListEntity that matches the criteria provided.
    func search(filter: SearchFilterEntity, cancelPreviousSearchIfNeeded: Bool) async throws -> NodeListEntity
}

public final class FilesSearchUseCase: FilesSearchUseCaseProtocol {

    private let repo: any FilesSearchRepositoryProtocol
    private let nodeRepository: any NodeRepositoryProtocol
    
    public init(
        repo: any FilesSearchRepositoryProtocol,
        nodeRepository: any NodeRepositoryProtocol
    ) {
        self.repo = repo
        self.nodeRepository = nodeRepository
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
    
    public func search(filter: SearchFilterEntity, page: SearchPageEntity, cancelPreviousSearchIfNeeded: Bool) async throws -> [NodeEntity] {
        if cancelPreviousSearchIfNeeded {
            repo.cancelSearch()
        }
        return try await repo.search(filter: filter, page: page)
    }
    
    public func search(filter: SearchFilterEntity, cancelPreviousSearchIfNeeded: Bool) async throws -> [NodeEntity] {
        if cancelPreviousSearchIfNeeded {
            repo.cancelSearch()
        }
        return try await repo.search(filter: filter)
    }
    
    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        nodeRepository.nodeUpdates
    }
}
