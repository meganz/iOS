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
            var context: (SearchResult) -> Void = { _ in }
            bridge = SearchBridge(
                selection: { selection($0) },
                context: { context($0) }
            )
            sut = SearchResultsViewModel(
                resultsProvider: resultsProvider,
                bridge: bridge
            )
            selection = {
                self.selectedResults.append($0)
            }
            context = {
                self.contextTriggeredResults.append($0)
            }
        }
        
        func withResultsPrepared() -> Self {
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
                !self.sut.listItems.isEmpty
            })
        }
    }
    
    func testListItems_onStart_hasNoItems() {
        let harness = Harness(self)
        XCTAssertEqual(harness.sut.listItems, [])
    }
    
    func testChangingQuery_asksResultsProviderToPerformSearch() async {
        let harness = Harness(self).withResultsPrepared()
        harness.sut.queryChanged(to: "query")
        await wait(until: {
            harness.resultsProvider.passedInQueries == [.query("query")]
        })
    }
    
    func testListItems_onQueryChanged_returnsResultsFromResultsProvider() async {
        let harness = Harness(self).withResultsPrepared()
        harness.sut.queryChanged(to: "query")
        await wait(until: {
            harness.sut.listItems == [.init(with: .sampleResult, contextAction: {}, selectionAction: {})]
        })
    }
    
    func testListItems_onQueryCleaned_clearsAnyResults() async {
        let harness = Harness(self).withResultsPrepared()
        harness.sut.queryChanged(to: "query")
        await wait(until: {
            !harness.sut.listItems.isEmpty
        })
        harness.sut.queryCleaned()
        await wait(until: {
            harness.sut.listItems.isEmpty
        })
    }
    
    func testOnSelectionAction_passesSelectedResultViaBridge() async throws {
        let harness = Harness(self).withResultsPrepared()
        await harness.searchAndWaitForResults(query: "query")
        let item = try XCTUnwrap(harness.sut.listItems.first)
        item.selectionAction()
        XCTAssertEqual(harness.selectedResults, [.sampleResult])
    }
    
    func testOnContextAction_passesSelectedResultViaBridge() async throws {
        let harness = Harness(self).withResultsPrepared()
        await harness.searchAndWaitForResults(query: "query")
        let item = try XCTUnwrap(harness.sut.listItems.first)
        item.contextAction()
        XCTAssertEqual(harness.contextTriggeredResults, [.sampleResult])
    }
}

fileprivate extension SearchQueryEntity {
    static func query(_ string: String) -> Self {
        .init(
            query: string,
            sorting: .automatic,
            mode: .home,
            chips: []
        )
    }
}

fileprivate extension SearchResult {
    static var sampleResult: Self {
        .init(
            id: "0",
            title: "title",
            description: "desc",
            properties: [],
            thumbnailImageData: { Data() },
            type: .node
        )
    }
}
