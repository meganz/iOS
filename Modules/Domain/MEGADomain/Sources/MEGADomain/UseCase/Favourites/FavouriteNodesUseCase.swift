import AsyncAlgorithms
import Foundation

public protocol FavouriteNodesUseCaseProtocol: Sendable {
    
    /// Get all favourite nodes for the active account and filter the result by the search query and the specified exclusion criteria. The result will exclude sensitive results based on account global showHiddenNodes preference.
    /// - Parameters:
    ///   - searchString: Search text used to case insensitively filter the Node results by their name, if the search term is included in the name it will return true. If nil, no name filtering is applied.
    /// - Returns: List of Favourited nodes, filtered by search and exclusion criteria.
    func allFavouriteNodes(searchString: String?) async throws -> [NodeEntity]
    
    /// Get all favourite nodes for the active account and filter the result by the search query and the specified exclusion criteria.
    /// - Parameters:
    ///   - searchString: Search text used to case insensitively filter the Node results by their name, if the search term is included in the name it will return true. If nil, no name filtering is applied.
    ///   - excludeSensitives: True, indicates that the returned result will not include any sensitively inherited nodes.
    ///   - limit: Number of nodes to return, if value is 0 or below it will return all nodes.
    /// - Returns: List of Favourited nodes, filtered by search and exclusion criteria.
    func allFavouriteNodes(searchString: String?, excludeSensitives: Bool, limit: Int) async throws -> [NodeEntity]
}

public struct FavouriteNodesUseCase<T: FavouriteNodesRepositoryProtocol, U: NodeRepositoryProtocol, V: SensitiveDisplayPreferenceUseCaseProtocol>: FavouriteNodesUseCaseProtocol {
    
    private let repo: T
    private let nodeRepository: U
    private let sensitiveDisplayPreferenceUseCase: V
    
    public init(repo: T,
                nodeRepository: U,
                sensitiveDisplayPreferenceUseCase: V) {
        
        self.repo = repo
        self.nodeRepository = nodeRepository
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
    }
    
    public func allFavouriteNodes(searchString: String?) async throws -> [NodeEntity] {
        try await allFavouriteNodes(searchString: searchString, overrideExcludeSensitives: nil)
    }
    
    public func allFavouriteNodes(searchString: String?, excludeSensitives: Bool, limit: Int) async throws -> [NodeEntity] {
        try await allFavouriteNodes(searchString: searchString, overrideExcludeSensitives: excludeSensitives, limit: limit)
    }
    
    private func allFavouriteNodes(searchString: String?, overrideExcludeSensitives: Bool?, limit: Int? = nil) async throws -> [NodeEntity] {
        
        let nodes = try await repo.allFavouritesNodes(searchString: searchString, limit: limit ?? 0)
        
        let excludedSensitiveNodes = if await shouldExcludeSensitive(override: overrideExcludeSensitives) {
            try await withThrowingTaskGroup(of: (Int, NodeEntity?).self, returning: [NodeEntity].self) { taskGroup in
                let nodeRepository = self.nodeRepository
                for (index, node) in nodes.enumerated() {
                    _ = taskGroup.addTaskUnlessCancelled {
                        let optionalNode: NodeEntity? = if node.isMarkedSensitive {
                            nil
                        } else if try await nodeRepository.isInheritingSensitivity(node: node) {
                            nil
                        } else {
                            node
                        }
                        return (index, optionalNode)
                    }
                }
                return try await taskGroup
                    .reduce(into: Array(repeating: Optional<NodeEntity>.none, count: nodes.count)) { $0[$1.0] = $1.1 }
                    .compactMap { $0 }
            }
        } else {
            nodes
        }
        
        return if let limit, limit > 0 {
            Array(excludedSensitiveNodes.prefix(limit))
        } else {
            excludedSensitiveNodes
        }
    }

    private func shouldExcludeSensitive(override: Bool?) async -> Bool {
        if let override {
            override
        } else {
            await sensitiveDisplayPreferenceUseCase.excludeSensitives()
        }
    }
}
