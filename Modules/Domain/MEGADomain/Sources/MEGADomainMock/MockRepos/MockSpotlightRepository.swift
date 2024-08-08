import Foundation
import MEGADomain
import MEGASwift

public struct MockSpotlightRepository: SpotlightRepositoryProtocol {
    
    public static var newRepo: MockSpotlightRepository {
        MockSpotlightRepository()
    }

    public let isIndexingAvailable: Bool
    
    public enum MockEvents: Sendable, Equatable {
        case deleteAllSearchableItems
        case indexSearchableItems([SpotlightSearchableItemEntity])
        case deleteSearchableItems([String])
    }
    
    // Internal State
    @Atomic public var mockEvents: [MockEvents] = []
    
    public init(isIndexingAvailable: Bool = true) {
        self.isIndexingAvailable = isIndexingAvailable
    }
    
    
    public func deleteAllSearchableItems() async throws {
        $mockEvents.mutate { $0.append(.deleteAllSearchableItems) }
    }
    
    public func indexSearchableItems(_ items: [SpotlightSearchableItemEntity]) async throws {
        $mockEvents.mutate { $0.append(.indexSearchableItems(items)) }
    }
    
    public func deleteSearchableItems(withIdentifiers identifiers: [String]) async throws {
        $mockEvents.mutate { $0.append(.deleteSearchableItems(identifiers)) }
    }
}
