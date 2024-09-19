import MEGADomain
import MEGARepo
import XCTest

final class VisualMediaSearchHistoryCacheRepositoryTests: XCTestCase {

    func testAddSearchHistory_entryProvided_shouldAddToSearchResults() async {
        let entry = SearchTextHistoryEntryEntity(id: UUID(), query: "query", searchDate: Date())
        let sut = makeSUT()
        
        await sut.add(entry: entry)
        
        let historyItems = await sut.history()
        XCTAssertEqual(historyItems, [entry])
    }
    
    func testDeleteSearchHistory_entryAlreadyAdded_shouldDeleteItemsFromHistory() async {
        let entry = SearchTextHistoryEntryEntity(id: UUID(), query: "query", searchDate: Date())
        let sut = makeSUT()
        
        await sut.add(entry: entry)
        
        let historyItemsAfterAdd = await sut.history()
        XCTAssertEqual(historyItemsAfterAdd, [entry])
        
        await sut.delete(entry: entry)
        
        let historyItems = await sut.history()
        XCTAssertTrue(historyItems.isEmpty)
    }

    private func makeSUT() -> VisualMediaSearchHistoryCacheRepository {
        VisualMediaSearchHistoryCacheRepository()
    }
}
