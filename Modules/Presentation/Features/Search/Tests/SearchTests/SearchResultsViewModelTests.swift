@testable import MEGASwift
@testable import Search
import SearchMock
import SwiftUI
import XCTest

extension SearchResultSelection: Equatable {
    public static func == (lhs: SearchResultSelection, rhs: SearchResultSelection) -> Bool {
        lhs.result == rhs.result &&
        lhs.siblings() == rhs.siblings()
    }
}

fileprivate extension Color {
    static let deselectedColor = SearchConfig.testConfig.chipAssets.normalBackground
    static let selectedColor = SearchConfig.testConfig.chipAssets.selectedBackground
}

@MainActor
final class SearchResultsViewModelTests: XCTestCase {
    class Harness {
        struct EmptyContent: Equatable {
            let chip: SearchChipEntity?
            let isSearchActive: Bool
        }

        static let emptyImageToReturn = Image("sun.min")
        let sut: SearchResultsViewModel
        let resultsProvider: MockSearchResultsProviding
        let bridge: SearchBridge
        var selectedResults: [SearchResultSelection] = []
        var contextTriggeredResults: [SearchResult] = []
        var keyboardResignedCount = 0
        var chipTaps: [(SearchChipEntity, Bool)] = []
        var emptyContentRequested: [EmptyContent] = []
        weak var testcase: XCTestCase?
        
        init(_ testcase: XCTestCase) {
            self.testcase = testcase
            resultsProvider = MockSearchResultsProviding()
            
            var selection: (SearchResultSelection) -> Void = { _ in }
            var context: (SearchResult, UIButton) -> Void = { _, _ in }
            var chipTapped: (SearchChipEntity, Bool) -> Void = { _, _ in }
            var keyboardResigned = {}
            
            bridge = SearchBridge(
                selection: { selection($0) },
                context: { context($0, $1) },
                resignKeyboard: { keyboardResigned() },
                chipTapped: { chipTapped($0, $1) }
            )

            var askedForEmptyContent: (SearchChipEntity?, SearchQuery) -> SearchConfig.EmptyViewAssets = {
                SearchConfig.testConfig.emptyViewAssetFactory($0, $1)
            }

            let base = SearchConfig.testConfig
            let config = SearchConfig(
                chipAssets: base.chipAssets,
                emptyViewAssetFactory: { chip, query in
                    askedForEmptyContent(chip, query)
                },
                rowAssets: base.rowAssets,
                colorAssets: base.colorAssets,
                contextPreviewFactory: base.contextPreviewFactory
            )
            
            sut = SearchResultsViewModel(
                resultsProvider: resultsProvider,
                bridge: bridge,
                config: config,
                layout: .list,
                showLoadingPlaceholderDelay: 0.1,
                keyboardVisibilityHandler: MockKeyboardVisibilityHandler()
            )
            selection = {
                self.selectedResults.append($0)
            }
            context = { result, _ in
                self.contextTriggeredResults.append(result)
            }
            keyboardResigned = {
                self.keyboardResignedCount += 1
            }
            chipTapped = { chip, isSelected in
                self.chipTaps.append((chip, isSelected))
            }
            
            askedForEmptyContent = {
                self.emptyContentRequested.append(.init(chip: $0, isSearchActive: $1.isSearchActive))
                return SearchConfig.testConfig.emptyViewAssetFactory($0, $1)
            }
        }
        
        @discardableResult
        func withSingleResultPrepared(_ title: String = "title") -> Self {
            let results = SearchResultsEntity(
                results: [
                    .resultWith(id: 1, title: title)
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
                availableChips: Array(1...idx).map { .init(type: .nodeFormat($0), title: "chip_\($0)")},
                appliedChips: []
            )
            
            resultsProvider.resultFactory = { _ in
                return results
            }
            
            return self
        }
        
        @discardableResult
        func noResultsWithSingleChipApplied() -> Self {
            resultsProvider.resultFactory = { _ in
                let results = SearchResultsEntity(
                    results: [],
                    availableChips: [.init(type: .nodeFormat(1), title: "appliedChip")],
                    appliedChips: [.init(type: .nodeFormat(1), title: "appliedChip")]
                )
                return results
            }
            return self
        }
        
        @discardableResult
        func withResultsPrepared(_ idx: UInt64) -> Self {
            let range = 1...idx
            let results = SearchResultsEntity(
                results: Array(range).map {
                    .resultWith(id: $0, title: "\($0)")
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
        XCTAssertEqual(harness.sut.chipsItems.map(\.id), ["chip_2"])
    }
    
    func testChangingQuery_asksResultsProviderToPerformSearch() async {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.task()
        await harness.sut.queryChanged(to: "query", isSearchActive: true)
        let expectedReceivedQueries: [SearchQuery] = [
            .initial,
            .userSupplied(.query("query", isSearchActive: true))
        ]
        XCTAssertEqual(harness.resultsProvider.passedInQueries, expectedReceivedQueries)
    }
    
    func testListItems_onQueryChanged_returnsResultsFromResultsProvider() async {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.queryChanged(to: "query", isSearchActive: true)
        let expectedListItems: [SearchResultRowViewModel] = [
            .init(
                result: .resultWith(
                    id: 1,
                    title: "title",
                    backgroundDisplayMode: .preview
                ),
                rowAssets: .init(
                    contextImage: UIImage(systemName: "ellipsis")!,
                    itemSelected: UIImage(systemName: "ellipsis")!,
                    itemUnselected: UIImage(systemName: "ellipsis")!,
                    playImage: UIImage(systemName: "ellipsis")!,
                    downloadedImage: UIImage(systemName: "ellipsis")!,
                    moreList: UIImage(systemName: "ellipsis")!,
                    moreGrid: UIImage(systemName: "ellipsis")!
                ),
                colorAssets: .init(
                    F7F7F7: Color("F7F7F7"),
                    _161616: Color("161616"),
                    _545458: Color("545458"),
                    CE0A11: Color("CE0A11"),
                    F30C14: Color("F30C14"),
                    F95C61: Color("F95C61"),
                    F7363D: Color("F7363D"),
                    _1C1C1E: Color("1C1C1E"),
                    _00A886: Color("00A886"),
                    _3C3C43: Color("3C3C43")
                ),
                previewContent: .init(
                    actions: [],
                    previewMode: .noPreview
                ),
                actions: .init(
                    contextAction: { _ in},
                    selectionAction: {},
                    previewTapAction: {}
                )
            )
        ]
        XCTAssertEqual(harness.sut.listItems, expectedListItems)
    }
    
    func testListItems_onQueryCleaned_sendsEmptyQuery_toProvider() async throws {
        let harness = Harness(self).withResultsPrepared(10) // 10 results
        await harness.sut.task()
        XCTAssertTrue(harness.hasExactlyResults(count: 10))
        harness.withSingleResultPrepared("5")
        await harness.sut.queryChanged(to: "5", isSearchActive: true)
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
        await harness.sut.queryChanged(to: "query", isSearchActive: true)
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
        await harness.sut.queryChanged(to: "query", isSearchActive: true)
        let item = try XCTUnwrap(harness.sut.listItems.first)
        item.actions.selectionAction()
        XCTAssertEqual(harness.selectedResults, [.resultSelectionWith(id: 1, title: "title")])
    }
    
    func testOnContextAction_passesSelectedResultViaBridge() async throws {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.queryChanged(to: "query", isSearchActive: true)
        let item = try XCTUnwrap(harness.sut.listItems.first)
        item.actions.contextAction(UIButton())
        XCTAssertEqual(harness.contextTriggeredResults, [.resultWith(id: 1, title: "title")])
    }
    
    func testListItems_showResultsTitleAndDescription() async {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.queryChanged(to: "query", isSearchActive: true)
        let result = harness.resultVM(at: 0)
        XCTAssertEqual(result.title, "title")
        XCTAssertEqual(result.result.description(.list), "Desc")
    }

    func testListItems_shouldBeUpdated_whenNodeChanges() async throws {
        let harness = Harness(self).withResultsPrepared(5)
        await harness.sut.task()
        let initialProperties = harness.resultVM(at: 1).result.properties
        let property: ResultProperty = .init(
            id: "1",
            content: .icon(
                image: UIImage(systemName: "ellipsis")!,
                scalable: false
            ),
            vibrancyEnabled: false,
            placement: { _  in return .prominent }
        )
        await harness.sut.searchResultUpdated(.resultWith(
            id: 2,
            title: "2",
            properties: [property]
        ))
        let updatedProperties = harness.resultVM(at: 1).result.properties
        XCTAssertNotEqual(initialProperties, updatedProperties)
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
        XCTAssertEqual(selectedChipItems.map(\.id), expectedIds)
    }
    
    func testEmptyView_isNil_whenItemsNotEmpty() async {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.queryChanged(to: "query", isSearchActive: true)
        XCTAssertNil(harness.sut.emptyViewModel)
    }
    
    func testEmptyView_notNil_whenItemsEmpty() async throws {
        let harness = Harness(self)
        await harness.sut.queryChanged(to: "query", isSearchActive: true)
        let contentUnavailableVM = try XCTUnwrap(harness.sut.emptyViewModel)
        let expectedContent = SearchConfig.EmptyViewAssets.testAssets
        XCTAssertEqual(contentUnavailableVM.image, expectedContent.image)
        XCTAssertEqual(contentUnavailableVM.title, expectedContent.title)
    }
    
    func testEmptyView_isDefault_whenChipSelected_AndQueryNotEmpty() async throws {
        let harness = Harness(self).withChipsPrepared(2)
        await harness.sut.queryChanged(to: "query", isSearchActive: true)
        await harness.sut.chipsItems.first!.select()
        _ = try XCTUnwrap(harness.sut.emptyViewModel)
        let content: Harness.EmptyContent = .init(chip: nil, isSearchActive: true)
        XCTAssertEqual(harness.emptyContentRequested, [content, content])
    }

    func testEmptyView_isContextualBasedOnChip_whenChipSelected_AndQueryEmpty() async throws {
        let harness = Harness(self)
        await harness.sut.queryChanged(to: "", isSearchActive: false)
        harness.noResultsWithSingleChipApplied()
        await harness.sut.chipsItems.first!.select()
        _ = try XCTUnwrap(harness.sut.emptyViewModel)
        let content: [Harness.EmptyContent] = [
            .init(chip: nil, isSearchActive: false),
            .init(
                chip: .some(.init(type: .nodeFormat(1), title: "appliedChip")), 
                isSearchActive: false
            )
        ]
        XCTAssertEqual(harness.emptyContentRequested, content)
    }

    func testOnProlongedLoading_shouldDisplayShimmerLoadingView() async {
        let harness = Harness(self).withSingleResultPrepared()

        XCTAssertFalse(harness.sut.isLoadingPlaceholderShown)
        await harness.sut.showLoadingPlaceholderIfNeeded()

        let delayExpectation = XCTestExpectation()
        delayExpectation.isInverted = true

        await fulfillment(of: [delayExpectation], timeout: 0.2)
        XCTAssertTrue(harness.sut.isLoadingPlaceholderShown)

        await harness.sut.queryChanged(to: "query", isSearchActive: true)
        XCTAssertFalse(harness.sut.isLoadingPlaceholderShown)
    }
    
    func testScrolled_callsBridgeResignKeyboard() {
        let harness = Harness(self)
        harness.sut.scrolled()
        XCTAssertEqual(harness.keyboardResignedCount, 1)
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

extension SearchResultRowViewModel: Equatable {
    // test only
    public static func == (lhs: Search.SearchResultRowViewModel, rhs: Search.SearchResultRowViewModel) -> Bool {
        lhs.result == rhs.result
    }
}
