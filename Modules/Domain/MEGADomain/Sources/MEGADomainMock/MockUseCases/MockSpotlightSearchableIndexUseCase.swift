import MEGADomain
import MEGASwift

public struct MockSpotlightSearchableIndexUseCase: SpotlightSearchableIndexUseCaseProtocol {
    
    @Atomic public var deleteAllSearchableItemsCalled: Bool = false
    @Atomic public var indexSearchableItemsCalledWith: [SpotlightSearchableItemEntity] = []
    @Atomic public var deleteSearchableItemsCalledWith: [String] = []
    
    public let isIndexingAvailable: Bool = true

    public init() { }
    
    public func deleteAllSearchableItems() async throws {
        $deleteAllSearchableItemsCalled.mutate { $0 = true }
    }
    
    public func indexSearchableItems(_ items: [SpotlightSearchableItemEntity]) async throws {
        $indexSearchableItemsCalledWith.mutate { $0 = items }
    }
    
    public func deleteSearchableItems(withIdentifiers identifiers: [String]) async throws {
        $deleteSearchableItemsCalledWith.mutate { $0 = identifiers }
    }
}
