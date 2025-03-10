import Foundation
import MEGADomain
import MEGARepo
import Testing

@Suite("VisualMediaSearchHistoryCacheRepository Tests")
struct VisualMediaSearchHistoryCacheRepositoryTests {

    @Test
    func testAddSearchHistory_entryProvided_shouldAddToSearchResults() async {
        let entry = SearchTextHistoryEntryEntity(id: UUID(), query: "query", searchDate: Date())
        let sut = makeSUT()
        
        await sut.add(entry: entry)
        
        let historyItems = await sut.history()
        #expect(historyItems == [entry])
    }
    
    @Test
    func testDeleteSearchHistory_entryAlreadyAdded_shouldDeleteItemsFromHistory() async {
        let entry = SearchTextHistoryEntryEntity(id: UUID(), query: "query", searchDate: Date())
        let sut = makeSUT()
        
        await sut.add(entry: entry)
        
        let historyItemsAfterAdd = await sut.history()
        #expect(historyItemsAfterAdd == [entry])
        
        await sut.delete(entry: entry)
        
        let historyItems = await sut.history()
        #expect(historyItems.isEmpty)
    }
    
    @Test("search same term it should replace with the later date")
    func again() async throws {
        let query = "query"
        
        let sut = makeSUT()
        
        await sut.add(entry: .init(id: UUID(), query: query, searchDate: Date()))
        await sut.add(entry: .init(id: UUID(), query: "other", searchDate: Date()))
        await sut.add(entry: .init(id: UUID(), query: query, searchDate: Date()))
        
        let historyItems = await sut.history().filter { $0.query == query }
        #expect(historyItems.count == 1)
    }

    private func makeSUT() -> VisualMediaSearchHistoryCacheRepository {
        VisualMediaSearchHistoryCacheRepository()
    }
}
