public protocol SpotlightSearchableIndexUseCaseProtocol: Sendable {
    
    /// Returns a Boolean value that indicates whether indexing is available on the current device.
    var isIndexingAvailable: Bool { get }
    
    ///  Removes all SearchAble Items created by application
    func deleteAllSearchableItems() async throws
    
    /// Add the following items into the CoreSpotlight indexer
    /// - Parameter items:List of SpotlightSearchableItemEntity items to to add to index]
    func indexSearchableItems(_ items: [SpotlightSearchableItemEntity]) async throws
    
    /// Delete all the associated searchable items that are linked to the list of nodes.
    /// - Parameter identifiers: Searchable items in relation to nodes to be removed.
    func deleteSearchableItems(withIdentifiers identifiers: [String]) async throws
}

public struct SpotlightSearchableIndexUseCase<T: SpotlightRepositoryProtocol>: SpotlightSearchableIndexUseCaseProtocol {
    
    private let spotlightRepository: T
    
    public var isIndexingAvailable: Bool { spotlightRepository.isIndexingAvailable  }
    
    public init(spotlightRepository: T) {
        self.spotlightRepository = spotlightRepository
    }
    
    public func deleteAllSearchableItems() async throws {
        try await spotlightRepository.deleteAllSearchableItems()
    }
    
    public func indexSearchableItems(_ items: [SpotlightSearchableItemEntity]) async throws {
        try await spotlightRepository.indexSearchableItems(items)
    }
    
    public func deleteSearchableItems(withIdentifiers identifiers: [String]) async throws {
        try await spotlightRepository.deleteSearchableItems(withIdentifiers: identifiers)
    }
}
