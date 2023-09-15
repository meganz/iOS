@testable import Search
import SearchMock
import SwiftUI
import XCTest

fileprivate extension Color {
    static let deselectedColor = SearchConfig.testConfig.chipAssets.normalBackground
    static let selectedColor = SearchConfig.testConfig.chipAssets.selectedBackground
}

@MainActor
final class SearchResultsViewModelTests: XCTestCase {
    class Harness {
        static let emptyImageToReturn = Image("sun.min")
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
                bridge: bridge,
                config: .testConfig
            )
            selection = {
                self.selectedResults.append($0)
            }
            context = { result, _ in
                self.contextTriggeredResults.append(result)
            }
        }
        
        @discardableResult
        func withSingleResultPrepared(_ title: String = "title") -> Self {
            let results = SearchResultsEntity(
                results: [
                    .sampleResult(title)
                ],
                availableChips: [],
                appliedChips: []
            )
            
            resultsProvider.resultFactory = { _ in
                return results
            }
            
            return self
        }
        
        @discardableResult
        func withChipsPrepared(_ idx: Int) -> Self {
            let results = SearchResultsEntity(
                results: [],
                availableChips: Array(1...idx).map { .init(id: $0, title: "chip_\($0)")},
                appliedChips: []
            )
            
            resultsProvider.resultFactory = { _ in
                return results
            }
            
            return self
        }
        
        @discardableResult
        func withResultsPrepared(_ idx: Int) -> Self {
            let results = SearchResultsEntity(
                results: Array(1...idx).map {
                    .sampleResult("\($0)")
                },
                availableChips: [],
                appliedChips: []
            )
            
            resultsProvider.resultFactory = { _ in
                return results
            }
            
            return self
        }
        
        var hasResults: Bool {
            !sut.listItems.isEmpty
        }
        
        var noResults: Bool {
            sut.listItems.isEmpty
        }
        
        func hasExactlyResults(count: Int) -> Bool {
            sut.listItems.count == count
        }
        
        func resultVM(at idx: Int) -> SearchResultRowViewModel {
            sut.listItems[idx]
        }
    }
    
    func testListItems_onStart_hasNoItemsAndSingleChipShown() async {
        let harness = Harness(self)
        harness.resultsProvider.resultFactory = { _ in
            .resultWithNoItemsAndSingleChip
        }
        await harness.sut.task()
        XCTAssertEqual(harness.sut.listItems, [])
        XCTAssertEqual(harness.sut.chipsItems.map(\.chipId), [2])
    }
    
    func testChangingQuery_asksResultsProviderToPerformSearch() async {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.task()
        await harness.sut.queryChanged(to: "query")
        let expectedReceivedQueries: [SearchQuery] = [
            .initial,
            .userSupplied(.query("query"))
        ]
        XCTAssertEqual(harness.resultsProvider.passedInQueries, expectedReceivedQueries)
    }
    
    func testListItems_onQueryChanged_returnsResultsFromResultsProvider() async {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.queryChanged(to: "query")
        let expectedListItems: [SearchResultRowViewModel] = [
            .init(with: .sampleResult("title"), contextButtonImage: UIImage(systemName: "ellipsis")!, contextAction: {_ in}, selectionAction: {})
        ]
        XCTAssertEqual(harness.sut.listItems, expectedListItems)
    }
    
    func testListItems_onQueryCleaned_sendsEmptyQuery_toProvider() async throws {
        let harness = Harness(self).withResultsPrepared(10) // 10 results
        await harness.sut.task()
        XCTAssertTrue(harness.hasExactlyResults(count: 10))
        harness.withSingleResultPrepared("5")
        await harness.sut.queryChanged(to: "5")
        XCTAssert(harness.hasExactlyResults(count: 1))
        harness.withResultsPrepared(10)
        await harness.sut.queryCleaned()
        XCTAssert(harness.hasExactlyResults(count: 10))
        let lastQuery = try XCTUnwrap(harness.resultsProvider.passedInQueries.last)
        XCTAssertEqual(lastQuery.query, "")
        XCTAssertEqual(lastQuery.chips, [])
    }
    
    func testListItems_onSearchCancelled_sendsEmptyQuery_toProvider() async throws {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.queryChanged(to: "query")
        let lastQueryBefore = try XCTUnwrap(harness.resultsProvider.passedInQueries.last)
        XCTAssertEqual(lastQueryBefore.query, "query")
        XCTAssertEqual(lastQueryBefore.chips, [])
        XCTAssert(harness.hasResults)
        await harness.sut.searchCancelled()
        let lastQueryAfter = try XCTUnwrap(harness.resultsProvider.passedInQueries.last)
        XCTAssertEqual(lastQueryAfter.query, "")
        XCTAssertEqual(lastQueryAfter.chips, [])
    }
    
    func testOnSelectionAction_passesSelectedResultViaBridge() async throws {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.queryChanged(to: "query")
        let item = try XCTUnwrap(harness.sut.listItems.first)
        item.selectionAction()
        XCTAssertEqual(harness.selectedResults, [.sampleResult("title")])
    }
    
    func testOnContextAction_passesSelectedResultViaBridge() async throws {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.queryChanged(to: "query")
        let item = try XCTUnwrap(harness.sut.listItems.first)
        item.contextAction(UIButton())
        XCTAssertEqual(harness.contextTriggeredResults, [.sampleResult("title")])
    }
    
    func testListItems_showResultsTitleAndDescription() async {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.queryChanged(to: "query")
        let result = harness.resultVM(at: 0)
        XCTAssertEqual(result.title, "title")
        XCTAssertEqual(result.subtitle, "desc")
    }
    
    func testChipItems_byDefault_noChipsSelected() async {
        let harness = Harness(self).withChipsPrepared(4)
        await harness.sut.task()
        let allDeselected = harness.sut.chipsItems.allSatisfy {
            $0.pill.background == .deselectedColor
        }
        XCTAssertTrue(allDeselected)
    }
    
    func testChipItems_appliedChips_isSelected() async {
        let harness = Harness(self)
        harness.resultsProvider.resultFactory = { _ in .resultsWithSingleChipApplied }
        
        await harness.sut.task()
        let selectedChipItems = harness.sut.chipsItems.filter {
            $0.pill.background == .selectedColor
        }
        let expectedIds = [SearchResultsEntity.resultsWithSingleChipApplied.appliedChips.first!.id]
        XCTAssertEqual(selectedChipItems.map(\.chipId), expectedIds)
    }
    
    func testEmptyView_isNil_whenItemsNotEmpty() async {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.queryChanged(to: "query")
        XCTAssertNil(harness.sut.emptyViewModel)
    }
    
    func testEmptyView_notNil_whenItemsEmpty() async throws {
        let harness = Harness(self)
        await harness.sut.queryChanged(to: "query")
        let contentUnavailableVM = try XCTUnwrap(harness.sut.emptyViewModel)
        let expectedContent = SearchConfig.EmptyViewAssets.testAssets
        XCTAssertEqual(contentUnavailableVM.image, expectedContent.image)
        XCTAssertEqual(contentUnavailableVM.title, expectedContent.title)
    }
}

fileprivate extension SearchResult {
    static func sampleResult(_ title: String) -> Self {
        .init(
            id: 1,
            title: title,
            description: "desc",
            properties: [],
            thumbnailImageData: { Data() },
            type: .node
        )
    }
}

fileprivate extension SearchResultsEntity {
    static let resultsWithSingleChipApplied = SearchResultsEntity(
        results: [],
        availableChips: [
            .chipWith(id: 1),
            .chipWith(id: 2),
            .chipWith(id: 3)
        ],
        appliedChips: [
            .chipWith(id: 1)
        ]
    )
}
