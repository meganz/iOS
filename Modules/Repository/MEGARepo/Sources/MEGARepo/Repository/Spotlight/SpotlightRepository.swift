@preconcurrency import CoreSpotlight
import Foundation
import MEGADomain

public struct SpotlightRepository: SpotlightRepositoryProtocol {

    public static var newRepo: Self {
        SpotlightRepository(searchableIndexer: .default())
    }
    
    public var isIndexingAvailable: Bool {
        CSSearchableIndex.isIndexingAvailable()
    }
    
    private let searchableIndexer: CSSearchableIndex
    
    public init(searchableIndexer: CSSearchableIndex) {
        self.searchableIndexer = searchableIndexer
    }
    
    public func deleteAllSearchableItems() async throws {
        try await searchableIndexer.deleteAllSearchableItems()
    }
    
    public func indexSearchableItems(_ items: [SpotlightSearchableItemEntity]) async throws {
        try await searchableIndexer.indexSearchableItems(items.map { $0.toCSSearchableItem() })
    }
    
    public func deleteSearchableItems(withIdentifiers identifiers: [String]) async throws {
        try await searchableIndexer.deleteSearchableItems(withIdentifiers: identifiers)
    }
}
