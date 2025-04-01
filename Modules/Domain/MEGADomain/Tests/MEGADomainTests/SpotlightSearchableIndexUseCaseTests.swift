import MEGADomain
import MEGADomainMock
import XCTest

final class SpotlightSearchableIndexUseCaseTests: XCTestCase {
    
    func testDeleteAllSearchableItems_shouldDeleteAllItems() async throws {
        let spotlightRepository = MockSpotlightRepository(isIndexingAvailable: true)
        let sut = sut(spotlightRepository: spotlightRepository)
        try await sut.deleteAllSearchableItems()
        
        XCTAssertEqual(spotlightRepository.mockEvents, [.deleteAllSearchableItems])
    }
    
    func testIndexSearchableItems_shouldIndexGivenItems() async throws {
        let spotlightRepository = MockSpotlightRepository(isIndexingAvailable: true)
        let sut = sut(spotlightRepository: spotlightRepository)
        let insertedItems: [SpotlightSearchableItemEntity] = [
            .init(uniqueIdentifier: "123", domainIdentifier: "tests", contentType: .data, title: "file1.png", contentDescription: "test file 1", thumbnailData: nil),
            .init(uniqueIdentifier: "456", domainIdentifier: "tests", contentType: .data, title: "file2.png", contentDescription: "test file 2", thumbnailData: nil),
            .init(uniqueIdentifier: "789", domainIdentifier: "tests", contentType: .data, title: "file3.png", contentDescription: "test file 3", thumbnailData: nil)
        ]
        
        try await sut.indexSearchableItems(insertedItems)
        
        XCTAssertEqual(spotlightRepository.mockEvents, [.indexSearchableItems(insertedItems)])
    }
    
    func testDeleteSearchableItems_shouldRemoveGivenItems() async throws {
        let spotlightRepository = MockSpotlightRepository(isIndexingAvailable: true)
        let sut = sut(spotlightRepository: spotlightRepository)
        let itemsToBeRemoved: [String] = [
            "123",
            "456",
            "789"
        ]
        
        try await sut.deleteSearchableItems(withIdentifiers: itemsToBeRemoved)
        
        XCTAssertEqual(spotlightRepository.mockEvents, [.deleteSearchableItems(itemsToBeRemoved)])
    }
}

extension SpotlightSearchableIndexUseCaseTests {
    
    private func sut(spotlightRepository: MockSpotlightRepository = .newRepo) -> SpotlightSearchableIndexUseCase<MockSpotlightRepository> {
        SpotlightSearchableIndexUseCase(
            spotlightRepository: spotlightRepository)
    }
}
