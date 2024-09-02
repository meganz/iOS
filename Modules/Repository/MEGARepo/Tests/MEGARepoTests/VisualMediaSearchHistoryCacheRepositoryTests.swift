import MEGADomain
import MEGARepo
import XCTest

final class VisualMediaSearchHistoryCacheRepositoryTests: XCTestCase {

    func testAddSearchHistory_entryProvided_shouldAddToSearchResults() async {
        let entry = SearchTextHistoryEntryEntity(id: UUID(), query: "query", searchDate: Date())
        let sut = makeSUT()
        
        await sut.addSearchHistory(entry: entry)
        
        let historyItems = await sut.searchQueryHistory()
        XCTAssertEqual(historyItems, [entry])
    }
    
    func testDeleteSearchHistory_entryAlreadyAdded_shouldDeleteItemsFromHistory() async {
        let entry = SearchTextHistoryEntryEntity(id: UUID(), query: "query", searchDate: Date())
        let sut = makeSUT()
        
        await sut.addSearchHistory(entry: entry)
        
        let historyItemsAfterAdd = await sut.searchQueryHistory()
        XCTAssertEqual(historyItemsAfterAdd, [entry])
        
        await sut.deleteSearchHistory(entry: entry)
        
        let historyItems = await sut.searchQueryHistory()
        XCTAssertTrue(historyItems.isEmpty)
    }

    private func makeSUT() -> VisualMediaSearchHistoryCacheRepository {
        VisualMediaSearchHistoryCacheRepository()
    }
}
