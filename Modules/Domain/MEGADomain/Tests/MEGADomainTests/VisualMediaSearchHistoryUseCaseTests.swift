import MEGADomain
import MEGADomainMock
import XCTest

final class VisualMediaSearchHistoryUseCaseTests: XCTestCase {

    func testSearchQueryHistory_whenSuccess_shouldReturnCorrectSearchHistoryItems() async throws {
        let storedItems = [
            SearchTextHistoryEntryEntity(query: "query", searchDate: try "2024-06-01T08:00:00Z".date),
            SearchTextHistoryEntryEntity(query: "query2", searchDate: try "2024-10-02T08:00:00Z".date),
        ]
        let repository = MockVisualMediaSearchHistoryRepository(searchQueryHistory: storedItems)
        let sut = makeSUT(visualMediaSearchHistoryRepository: repository)
        
        let searchHistoryItems = await sut.history()
        
        let expectedItems = storedItems.sorted { $0.searchDate > $1.searchDate }
        XCTAssertEqual(searchHistoryItems, expectedItems)
    }
    
    func testAddSearchHistory_storedIsLessThanMax_shouldJustAddSearchHistoryEntry() async {
        let entry = SearchTextHistoryEntryEntity(query: "query")
        let repository = MockVisualMediaSearchHistoryRepository(searchQueryHistory: [])
        let sut = makeSUT(visualMediaSearchHistoryRepository: repository)
        
        await sut.add(entry: entry)
        
        let invocations = await repository.invocations
        XCTAssertEqual(invocations, [.add(entry: entry), .history])
    }
    
    func testAddSearchHistory_storedWillBeMoreThanMax_shouldAddSearchHistoryEntryAndRemoveTheOldest() async throws {
        let entry = SearchTextHistoryEntryEntity(query: "new query", searchDate: Date())
        let expectedDeletedItem =  SearchTextHistoryEntryEntity(query: "query6", searchDate: try "2024-01-01T08:00:00Z".date)
        let expectedItems = [
            entry,
            SearchTextHistoryEntryEntity(query: "query", searchDate: try "2024-06-01T08:00:00Z".date),
            SearchTextHistoryEntryEntity(query: "query2", searchDate: try "2024-05-01T08:00:00Z".date),
            SearchTextHistoryEntryEntity(query: "query3", searchDate: try "2024-04-01T08:00:00Z".date),
            SearchTextHistoryEntryEntity(query: "query4", searchDate: try "2024-03-01T08:00:00Z".date),
            SearchTextHistoryEntryEntity(query: "query5", searchDate: try "2024-02-01T08:00:00Z".date),
            expectedDeletedItem
        ]
       
        let repository = MockVisualMediaSearchHistoryRepository(searchQueryHistory: expectedItems)
        let sut = makeSUT(visualMediaSearchHistoryRepository: repository)
        
        await sut.add(entry: entry)
        
        let invocations = await repository.invocations
        XCTAssertEqual(invocations, [.add(entry: entry),
                                     .history,
                                     .delete(entry: expectedDeletedItem)])
    }
    
    private func makeSUT(
        visualMediaSearchHistoryRepository: MockVisualMediaSearchHistoryRepository = MockVisualMediaSearchHistoryRepository()
    ) -> VisualMediaSearchHistoryUseCase<MockVisualMediaSearchHistoryRepository> {
        VisualMediaSearchHistoryUseCase(
            visualMediaSearchHistoryRepository: visualMediaSearchHistoryRepository)
    }
}
