@testable import Search
import SearchMock
import XCTest

@MainActor
final class SearchResultsViewModelTests: XCTestCase {
    class Harness {
        let sut: SearchResultsViewModel
        let resultsProvider: MockSearchResultsProviding
        let bridge: SearchBridge
        var selectedResults: [SearchResult] = []
        var contextTriggeredResults: [SearchResult] = []
        weak var testcase: XCTestCase?
        
        init(_ testcase: XCTestCase) {
            self.testcase = testcase
            resultsProvider = MockSearchResultsProviding()
            var selection: (SearchResult) -> Void = { _ in }
            var context: (SearchResult, UIButton) -> Void = { _, _ in }
            bridge = SearchBridge(
                selection: { selection($0) },
                context: { context($0, $1) }
            )
            sut = SearchResultsViewModel(
                resultsProvider: resultsProvider,
                bridge: bridge
            )
            selection = {
                self.selectedResults.append($0)
            }
            context = { result, _ in
                self.contextTriggeredResults.append(result)
            }
        }
        
        func withSingleResultPrepared() -> Self {
            let results = SearchResultsEntity(
                results: [
                    .sampleResult
                ],
                chips: []
            )
            
            resultsProvider.resultFactory = { _ in
                return results
            }
            
            return self
        }
        
        func searchAndWaitForResults(query: String) async {
            sut.queryChanged(to: query)
            await testcase?.wait(until: {
                self.hasResults
            })
        }
        
        var hasResults: Bool {
            !sut.listItems.isEmpty
        }
        
        var noResults: Bool {
            sut.listItems.isEmpty
        }
        
        func resultVM(at idx: Int) -> SearchResultRowViewModel {
            sut.listItems[idx]
        }
    }
    
    func testListItems_onStart_hasNoItems() {
        let harness = Harness(self)
        XCTAssertEqual(harness.sut.listItems, [])
    }
    
    func testChangingQuery_asksResultsProviderToPerformSearch() async {
        let harness = Harness(self).withSingleResultPrepared()
        harness.sut.queryChanged(to: "query")
        await wait(until: {
            harness.resultsProvider.passedInQueries == [.query("query")]
        })
    }
    
    func testListItems_onQueryChanged_returnsResultsFromResultsProvider() async {
        let harness = Harness(self).withSingleResultPrepared()
        harness.sut.queryChanged(to: "query")
        await wait(until: {
            harness.sut.listItems == [.init(with: .sampleResult, contextAction: {_ in}, selectionAction: {})]
        })
    }
    
    func testListItems_onQueryCleaned_clearsAnyResults() async {
        let harness = Harness(self).withSingleResultPrepared()
        harness.sut.queryChanged(to: "query")
        await wait(until: {
            harness.hasResults
        })
        harness.sut.queryCleaned()
        await wait(until: {
            harness.noResults
        })
    }
    
    func testListItems_onSearchCancelled_clearsAnyResults() async {
        let harness = Harness(self).withSingleResultPrepared()
        harness.sut.queryChanged(to: "query")
        await wait(until: {
            harness.hasResults
        })
        harness.sut.searchCancelled()
        await wait(until: {
            harness.noResults
        })
    }
    
    func testOnSelectionAction_passesSelectedResultViaBridge() async throws {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.searchAndWaitForResults(query: "query")
        let item = try XCTUnwrap(harness.sut.listItems.first)
        item.selectionAction()
        XCTAssertEqual(harness.selectedResults, [.sampleResult])
    }
    
    func testOnContextAction_passesSelectedResultViaBridge() async throws {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.searchAndWaitForResults(query: "query")
        let item = try XCTUnwrap(harness.sut.listItems.first)
        item.contextAction(UIButton())
        XCTAssertEqual(harness.contextTriggeredResults, [.sampleResult])
    }
    
    func testListItems_showResultsTitleAndDescription() async {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.searchAndWaitForResults(query: "query")
        let result = harness.resultVM(at: 0)
        XCTAssertEqual(result.title, "title")
        XCTAssertEqual(result.subtitle, "desc")
    }
}

fileprivate extension SearchResult {
    static var sampleResult: Self {
        .init(
            id: 1,
            title: "title",
            description: "desc",
            properties: [],
            thumbnailImageData: { Data() },
            type: .node
        )
    }
}
