import Combine
import MEGADomain
import MEGADomainMock
@testable import MEGAPhotos
import MEGATest
import XCTest

final class VisualMediaSearchResultsViewModelTests: XCTestCase {

    @MainActor
    func testMonitorSearchResults_emptyNoHistoryItems_shouldSetViewModeToEmpty() {
        let visualMediaSearchHistoryUseCase = MockVisualMediaSearchHistoryUseCase(
            searchQueryHistoryEntries: [])
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
    func testMonitorSearchResults_historyQueryItemsFound_shouldSetViewModeToRecentSearchedItems() throws {
        let historyItems = try makeHistoryEntries()
        let visualMediaSearchHistoryUseCase = MockVisualMediaSearchHistoryUseCase(
            searchQueryHistoryEntries: historyItems)
        
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
    func testMonitorSearchResult_searchUpdated_shouldShowEmptyThenLoadingWithSearchResultsWhenCompleted() async throws {
        let visualMediaSearchHistoryUseCase = MockVisualMediaSearchHistoryUseCase(
            searchQueryHistoryEntries: [])

        let sut = makeSUT(visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase)

        let emptyExp = expectation(description: "Empty Shown")
        let loadingExp = expectation(description: "loading shown")
        let searchResultsExp = expectation(description: "loading and search result shown")

        let subscription = viewStateUpdates(on: sut) {
            switch $0 {
            case .empty: emptyExp.fulfill()
            case .loading: loadingExp.fulfill()
            case .searchResults: searchResultsExp.fulfill()
            default: XCTFail("Unexpected view state \($0)")
            }
        }

        trackTaskCancellation { await sut.monitorSearchResults() }

        await fulfillment(of: [emptyExp], timeout: 0.2)

        sut.searchText = "Search"

        await fulfillment(of: [loadingExp, searchResultsExp], timeout: 0.2)
        subscription.cancel()
    }
    
    @MainActor
    func testUpdateSearchResult_emptyRetrievedHistoryAfterFirstSearch_shouldShowHistoryItemWhenSearchCleared() {
        let visualMediaSearchHistoryUseCase = MockVisualMediaSearchHistoryUseCase(
            searchQueryHistoryEntries: [])
        
        let sut = makeSUT(visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase)
        
        let exp = expectation(description: "search results")
        
        let subscription = viewStateUpdates(on: sut) {
            XCTAssertEqual($0, .searchResults(albums: [], photos: []))
            exp.fulfill()
        }
        
        trackTaskCancellation { await sut.monitorSearchResults() }
        
        sut.searchText = "1"
        sut.searchText = "2"
        sut.searchText = "queenstown trip"
        
        wait(for: [exp], timeout: 0.2)
        
        subscription.cancel()
    }
    
    @MainActor
    func testSaveSearch_searchTextNotEmpty_shouldAddItemToSearchHistory() async {
        let lastSearch = "queenstown trip"
        let visualMediaSearchHistoryUseCase = MockVisualMediaSearchHistoryUseCase()
        let sut = makeSUT(visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase)
        sut.searchText = lastSearch
        
        await sut.saveSearch()
        
        let invocations = await visualMediaSearchHistoryUseCase.invocations
        XCTAssertEqual(invocations.count, 1)
        if case .add(let entry) = invocations.last {
            XCTAssertEqual(entry.query, lastSearch)
        } else {
            XCTFail("Expected addSearchHistory invocation")
        }
    }

    @MainActor
    private func makeSUT(
        searchBarTextFieldUpdater: SearchBarTextFieldUpdater = SearchBarTextFieldUpdater(),
        visualMediaSearchHistoryUseCase: some VisualMediaSearchHistoryUseCaseProtocol = MockVisualMediaSearchHistoryUseCase(),
        searchDebounceTime: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(150),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> VisualMediaSearchResultsViewModel {
        let sut = VisualMediaSearchResultsViewModel(
            searchBarTextFieldUpdater: searchBarTextFieldUpdater,
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
        sorted(by: { $0.searchDate > $1.searchDate }).map(\.query)
    }
}
