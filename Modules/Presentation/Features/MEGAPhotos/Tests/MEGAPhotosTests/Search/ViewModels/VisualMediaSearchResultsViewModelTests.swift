import Combine
import MEGADomain
import MEGADomainMock
@testable import MEGAPhotos
import MEGATest
import XCTest

final class VisualMediaSearchResultsViewModelTests: XCTestCase {

    @MainActor
    func testUpdateSearchResults_emptyNoHistoryItems_shouldSetViewModeToEmpty() {
        let visualMediaSearchHistoryUseCase = MockVisualMediaSearchHistoryUseCase(
            searchQueryHistoryResult: .success([]))
        let sut = makeSUT(visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase)
        
        let exp = expectation(description: "recently searched items view state")
        let subscription = viewStateUpdates(on: sut) {
            XCTAssertEqual($0, .empty)
            exp.fulfill()
        }
        
        trackTaskCancellation { await sut.monitorSearchResults() }
        
        wait(for: [exp], timeout: 0.2)
        subscription.cancel()
    }
    
    @MainActor
    func testUpdateSearchResults_emptyHistoryItemsFound_shouldSetViewModeToRecentSearchedItems() throws {
        let historyItems = try makeHistoryEntries()
        let visualMediaSearchHistoryUseCase = MockVisualMediaSearchHistoryUseCase(
            searchQueryHistoryResult: .success(historyItems))
        
        let sut = makeSUT(visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase)
        
        let expectedItems = historyItems.sortedByDateQueries()
        let exp = expectation(description: "recently searched items view state")
        let subscription = viewStateUpdates(on: sut) {
            switch $0 {
            case .recentlySearched(let items):
                XCTAssertEqual(items.map(\.query), expectedItems)
                exp.fulfill()
            default:
                XCTFail("Unexpected view state \($0)")
            }
            
        }
        
        trackTaskCancellation { await sut.monitorSearchResults() }
        
        wait(for: [exp], timeout: 0.2)
        subscription.cancel()
    }
    
    @MainActor
    func testUpdateSearchResult_emptyRetrievedHistoryAfterFirstSearch_shouldShowHistoryItemWhenSearchCleared() {
        let visualMediaSearchHistoryUseCase = MockVisualMediaSearchHistoryUseCase(
            searchQueryHistoryResult: .success([]))
        
        let sut = makeSUT(visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase)
    
        let emptyExp = expectation(description: "empty state shown")
        let loadingWithSearchResults = expectation(description: "loading and search result shown")
        loadingWithSearchResults.expectedFulfillmentCount = 2
        let recentlySearchedExp = expectation(description: "recently searched items view state")
       
        let lastSearch = "3"
        
        let subscription = viewStateUpdates(on: sut) {
            switch $0 {
            case .empty: emptyExp.fulfill()
            case .loading, .searchResults: loadingWithSearchResults.fulfill()
            case .recentlySearched(let items):
                XCTAssertEqual(items.map(\.query), [lastSearch])
                recentlySearchedExp.fulfill()
            }
        }
        
        trackTaskCancellation { await sut.monitorSearchResults() }
        
        wait(for: [emptyExp], timeout: 0.2)
        
        sut.searchText = "1"
        sut.searchText = "2"
        sut.searchText = lastSearch
        
        wait(for: [loadingWithSearchResults], timeout: 0.2)
        
        sut.searchText = ""
    
        wait(for: [recentlySearchedExp], timeout: 0.2)
        subscription.cancel()
    }
    
    @MainActor
    func testUpdateSearchResults_historyLoadedAndSearchEntered_shouldSetViewStatesCorrectlyAndKeepRecentlySearchedItemWithHistoryItems() throws {
        let historyItems = try makeHistoryEntries()
        let visualMediaSearchHistoryUseCase = MockVisualMediaSearchHistoryUseCase(
            searchQueryHistoryResult: .success(historyItems))
        
        let sut = makeSUT(visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase)
        
        let recentlySearchedFirstExp = expectation(description: "recently searched history items")
        let recentlySearchedSecondExp = expectation(description: "recently searched items with last search as latest")
        let loadingWithSearchResults = expectation(description: "loading and search result shown")
        loadingWithSearchResults.expectedFulfillmentCount = 2
        
        let lastEnteredSearchItem = "last"
        let historyItemQueries = historyItems.sortedByDateQueries()
        var expectedItems = Array(historyItemQueries.prefix(5))
        expectedItems.insert(lastEnteredSearchItem, at: 0)
        
        var recentSearchedExpectedItems = [
            historyItemQueries,
            expectedItems
        ]
        var recentExpectationsToFull = [recentlySearchedFirstExp, recentlySearchedSecondExp]
        
        let subscription = viewStateUpdates(on: sut) {
            switch $0 {
            case .empty: XCTFail("Empty should not have been shown")
            case .loading, .searchResults: loadingWithSearchResults.fulfill()
            case .recentlySearched(let items):
                XCTAssertEqual(items.map(\.query), recentSearchedExpectedItems.removeFirst())
                recentExpectationsToFull.removeFirst().fulfill()
            }
        }
        
        trackTaskCancellation { await sut.monitorSearchResults() }
        
        wait(for: [recentlySearchedFirstExp], timeout: 0.2)
    
        sut.searchText = lastEnteredSearchItem
        
        wait(for: [loadingWithSearchResults], timeout: 0.2)
        
        sut.searchText = ""
        
        wait(for: [recentlySearchedSecondExp], timeout: 0.2)
        
        subscription.cancel()
    }
    
    @MainActor
    func testOnViewDisappear_recentItems_shouldStoreRecentItems() async throws {
        let historyItems = try makeHistoryEntries()
        let visualMediaSearchHistoryUseCase = MockVisualMediaSearchHistoryUseCase(
            searchQueryHistoryResult: .success(historyItems))
        
        let sut = makeSUT(visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase)
        
        let loadingWithSearchResults = expectation(description: "loading and search result shown")
        loadingWithSearchResults.expectedFulfillmentCount = 2
        let recentlySearchedExp = expectation(description: "recently searched items shown")
        
        let subscription = viewStateUpdates(on: sut) {
            switch $0 {
            case .loading, .searchResults: loadingWithSearchResults.fulfill()
            case .recentlySearched(let items):
                XCTAssertEqual(items.map(\.query), historyItems.sortedByDateQueries())
                recentlySearchedExp.fulfill()
            default: XCTFail("Unexpected view state \($0)")
            }
        }
    
        trackTaskCancellation { await sut.monitorSearchResults() }
        
        await fulfillment(of: [recentlySearchedExp], timeout: 0.2)
        
        let searchTerm = "Search"
        sut.searchText = searchTerm
       
        await fulfillment(of: [loadingWithSearchResults], timeout: 0.2)
        subscription.cancel()
        
        await sut.onViewDisappear()
        
        let expectedItems = latestSearchQueries(from: historyItems, lastSearch: searchTerm)
        let invocations = await visualMediaSearchHistoryUseCase.invocations
        XCTAssertEqual(invocations.count, 2)
        if case .save(let entries) = invocations.last {
            XCTAssertEqual(entries.map(\.query), expectedItems)
        } else {
            XCTFail("Expected save invocation")
        }
    }

    @MainActor
    private func makeSUT(
        visualMediaSearchHistoryUseCase: some VisualMediaSearchHistoryUseCaseProtocol = MockVisualMediaSearchHistoryUseCase(),
        searchDebounceTime: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(150),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> VisualMediaSearchResultsViewModel {
        let sut = VisualMediaSearchResultsViewModel(
            visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase,
            searchDebounceTime: searchDebounceTime)
        trackForMemoryLeaks(on: sut, timeoutNanoseconds: 1_000_000_000, file: file, line: line)
        return sut
    }
    
    @MainActor
    private func viewStateUpdates(on sut: VisualMediaSearchResultsViewModel, action: @escaping (VisualMediaSearchResultsViewModel.ViewState) -> Void) -> AnyCancellable {
        sut.$viewState
            .dropFirst()
            .sink(receiveValue: action)
    }
    
    private func makeHistoryEntries() throws -> [SearchTextHistoryEntryEntity] {
        [SearchTextHistoryEntryEntity(query: "1", searchDate: try "2024-01-01T22:00:00Z".date),
         SearchTextHistoryEntryEntity(query: "2", searchDate: try "2024-02-01T22:00:00Z".date),
         SearchTextHistoryEntryEntity(query: "3", searchDate: try "2024-03-01T22:00:00Z".date),
         SearchTextHistoryEntryEntity(query: "4", searchDate: try "2024-04-01T22:00:00Z".date),
         SearchTextHistoryEntryEntity(query: "5", searchDate: try "2024-05-01T22:00:00Z".date),
         SearchTextHistoryEntryEntity(query: "6", searchDate: try "2024-06-01T22:00:00Z".date)]
    }
    
    private func latestSearchQueries(from items: [SearchTextHistoryEntryEntity], lastSearch: String) -> [String] {
        var expectedItems = Array(items.sortedByDateQueries().prefix(5))
        expectedItems.insert(lastSearch, at: 0)
        return expectedItems
    }
}

private extension Sequence where Element == SearchTextHistoryEntryEntity {
    func sortedByDateQueries() -> [String] {
        sorted(by: { $0.searchDate > $1.searchDate }).toSearchHistoryItems().map(\.query)
    }
}
