import ConcurrencyExtras
@testable import MEGAUIKit
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
                chipTapped: { chipTapped($0, $1) },
                sortingOrder: { .nameAscending }
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
                keyboardVisibilityHandler: MockKeyboardVisibilityHandler(), 
                viewDisplayMode: .unknown
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
        func withResultsPrepared(count: UInt64, startingId: UInt64 = 1) -> Self {
            let range = startingId..<(startingId+count)
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
        
        @discardableResult
        func withSelectedNodes(_ selectedResults: [ResultId], currentResults: [ResultId]) -> Self {
            sut.selectedResultIds = Set(selectedResults)
            resultsProvider.currentResultIdsToReturn = currentResults
            return self
        }
        
        func resetResultFactory() {
            resultsProvider.resultFactory = { _ in return nil }
        }
        
        func simulateVisibleItems(startId: ResultId, endId: ResultId) async {
            await withTaskGroup(of: Void.self) { group in
                (startId...endId).compactMap { resultId in
                    sut.listItems.first(where: { $0.result.id == resultId })
                }.forEach { item in
                    group.addTask {
                        await self.sut.onItemAppear(item)
                    }
                }
            }
        }
        
        func simulateVisibleItemsRemoval(_ id: ResultId) async {
            guard let item = sut.listItems.first(where: { $0.result.id == id }) else { return }
            await sut.onItemDisappear(item)
            
        }
        
        func prepareRefreshedResults(startId: UInt64, endId: UInt64) {
            let results = Array(startId...endId).map {
                SearchResult.resultWith(id: $0, title: "refreshed \($0)")
            }
            resultsProvider.refreshedSearchResultsToReturn = .init(results: results, availableChips: [], appliedChips: [])
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
        XCTAssertTrue(harness.sut.listItems.isEmpty)
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
                    _3C3C43: Color("3C3C43"),
                    checkmarkBackgroundTintColor: Color(
                        UIColor {
                            $0.userInterfaceStyle == .dark 
                            ? UIColor(red: 0, green: 0.761, blue: 0.604, alpha: 1.0)
                            : UIColor(red: 0, green: 0.659, blue: 0.525, alpha: 1.0)
                        }
                    )
                ),
                previewContent: .init(
                    actions: [],
                    previewMode: .noPreview
                ),
                actions: .init(
                    contextAction: { _ in},
                    selectionAction: {},
                    previewTapAction: {}
                ),
                swipeActions: []
            )
        ]
        XCTAssertEqual(harness.sut.listItems.map(\.result), expectedListItems.map(\.result))
    }
    
    func testListItems_onQueryCleaned_sendsEmptyQuery_toProvider() async throws {
        let harness = Harness(self).withResultsPrepared(count: 10) // 10 results
        await harness.sut.task()
        XCTAssertTrue(harness.hasExactlyResults(count: 10))
        harness.withSingleResultPrepared("5")
        await harness.sut.queryChanged(to: "5", isSearchActive: true)
        XCTAssert(harness.hasExactlyResults(count: 1))
        harness.withResultsPrepared(count: 10)
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
        let harness = Harness(self).withResultsPrepared(count: 5)
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
    
    func testSelectAll_whenNoNodesAreSelected_shouldSelectAllNodes() {
        let currentNodes: [ResultId] = [1, 2, 3, 4]
        let harness = Harness(self).withSelectedNodes([], currentResults: currentNodes)
        let exp = expectation(description: "Wait for selection changed")
        var selectionChangeResult: Set<ResultId>?
        harness.bridge.selectionChanged = {
            selectionChangeResult = $0
            exp.fulfill()
        }
        harness.sut.toggleSelectAll()
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(harness.sut.selectedResultIds.sorted(), [1, 2, 3, 4])
        XCTAssertEqual(selectionChangeResult?.sorted(), [1, 2, 3, 4])
    }
    
    func testSelectAll_whenSomeNodesAreSelected_shouldSelectAllNodes() {
        let currentNodes: [ResultId] = [1, 2, 3, 4]
        let harness = Harness(self).withSelectedNodes([1, 2], currentResults: currentNodes)
        let exp = expectation(description: "Wait for selection changed")
        var selectionChangeResult: Set<ResultId>?
        harness.bridge.selectionChanged = {
            selectionChangeResult = $0
            exp.fulfill()
        }
        harness.sut.toggleSelectAll()
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(harness.sut.selectedResultIds.sorted(), [1, 2, 3, 4])
        XCTAssertEqual(selectionChangeResult?.sorted(), [1, 2, 3, 4])
    }
    
    func testSelectAll_whenAllNodesAreSelected_shouldDeselectAllNodes() {
        let currentNodes: [ResultId] = [1, 2, 3, 4]
        let harness = Harness(self).withSelectedNodes(currentNodes, currentResults: currentNodes)
        harness.resultsProvider.currentResultIdsToReturn = [1, 2, 3, 4]
        harness.sut.selectedResultIds = [1, 2, 3, 4]
        let exp = expectation(description: "Wait for selection changed")
        var selectionChangeResult: Set<ResultId>?
        harness.bridge.selectionChanged = {
            selectionChangeResult = $0
            exp.fulfill()
        }
        
        harness.sut.toggleSelectAll()
        wait(for: [exp], timeout: 1.0)

        XCTAssertTrue(harness.sut.selectedResultIds.isEmpty)
        XCTAssertTrue(selectionChangeResult?.isEmpty == true)
    }

    func testChangeSortOrder_forAllCases_shouldMatchTheExpectation() async {
        let allCases: [(Search.SortOrderEntity, [SearchQuery]?)] = [
            (.nameAscending, [.initial]),
            (.nameDescending, nil),
            (.largest, nil),
            (.smallest, nil),
            (.newest, nil),
            (.oldest, nil),
            (.label, nil),
            (.favourite, nil)
        ]

        for (sortOrderEntity, expectedQueries) in allCases {
            await assertChangeSortOrder(with: sortOrderEntity, expectedReceivedQueries: expectedQueries)
        }
    }

    func testReloadResults_whenPerformed_shouldReturnExpectedQueries() async {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.reloadResults()
        let expectedReceivedQueries: [SearchQuery] = [
            .initial
        ]
        XCTAssertEqual(harness.resultsProvider.passedInQueries, expectedReceivedQueries)
    }
    
    func testOnSearchResultsUpdated_whenGenericUpdate_shouldReturnExpectedResults() async {
        await withMainSerialExecutor {
            // given
            let harness = Harness(self).withResultsPrepared(count: 10) // Initially there are 10 results
            await harness.sut.task()
            harness.resetResultFactory()
            harness.prepareRefreshedResults(startId: 1, endId: 15) // After refreshing, there will be 15 results
            
            // Simulate visible items
            await harness.simulateVisibleItems(startId: 0, endId: 9)
            await harness.simulateVisibleItemsRemoval(9) // At this point, visible item will be [1...8]

            // when
            harness.bridge.onSearchResultsUpdated(.generic)
            
            for _ in 1...12 { // Needs to yield to make way for other concurrent tasks to fully finished first.
                await Task.yield()
            }
            
            // then
            XCTAssertEqual(harness.sut.listItems.map { $0.result.id }, Array(1...15))
            
            // Make sure to check the visible items' thumbnails are loaded
            for index in 0..<harness.sut.listItems.count {
                if index < 8 {
                    XCTAssertEqual(harness.sut.listItems[index].thumbnailImage.pngData()?.count, SearchResult.defaultThumbnailImageData.count)
                } else {
                    XCTAssertNil(harness.sut.listItems[index].thumbnailImage.pngData())
                }
            }
        }
    }
    
    func testOnSearchResultsUpdated_whenSpecificUpdate_shouldReturnExpectedResults() async {
        await withMainSerialExecutor {
            // given
            let harness = Harness(self).withResultsPrepared(count: 10)
            await harness.sut.task()
            
            harness.bridge.onSearchResultsUpdated(.specific(result: .resultWith(id: 1))) // Triggers item update
            await Task.yield()
            harness.bridge.onSearchResultsUpdated(.specific(result: .resultWith(id: 2))) // Triggers item updates
            await Task.yield()
            harness.bridge.onSearchResultsUpdated(.specific(result: .resultWith(id: 100))) // Not triggering item update
            await Task.yield()
            
            XCTAssertEqual(harness.sut.listItems[0].thumbnailImage.pngData()?.count, SearchResult.defaultThumbnailImageData.count)
            XCTAssertEqual(harness.sut.listItems[1].thumbnailImage.pngData()?.count, SearchResult.defaultThumbnailImageData.count)
            XCTAssertNil(harness.sut.listItems[2].thumbnailImage.pngData())
        }
    }

    func testSelectedRows_whenMultipleRowsSelected_shouldMatchResultsIds() {
        let harness = Harness(self)
        var selectedRows = Set<ResultId>()
        for i in 1...10 {
            selectedRows.insert(generateRandomSearchResultRowViewModel(id: i).id)
        }

        let exp = expectation(description: "Wait for selected results")
        let selectedResultsSubscription = harness
            .sut
            .$selectedResultIds
            .sink { results in
                if results == Set(1...10) {
                    exp.fulfill()
                }
            }

        harness.sut.selectedRowIds = selectedRows
        wait(for: [exp], timeout: 1.0)
        selectedResultsSubscription.cancel()
    }
    
    func testLoadMore_whenScrollingNearToTheBottomOfTheList_shouldTriggerLoadMoreItems() async {
        // given
        var harness = Harness(self).withResultsPrepared(count: 100) // Initially there are 100 results, id from 1 to 100
        await harness.sut.task()
        harness.resetResultFactory()
        XCTAssertEqual(harness.sut.listItems.map { $0.result.id }, Array(1...100))
        
        // when
        harness = harness.withResultsPrepared(count: 50, startingId: 101) // loading more 50 results, id from 101 to 150
        let item = harness.sut.listItems[80]
        await harness.sut.onItemAppear(item) // loading more should be triggered when item 80th appears
        
        // then
        XCTAssertEqual(harness.sut.listItems.map { $0.result.id }, Array(1...150)) // 50 more results loaded, hence 150 in total
    }

    private func generateRandomSearchResultRowViewModel(id: Int) -> SearchResultRowViewModel {
        .init(
            result: .init(
                id: UInt64(id),
                thumbnailDisplayMode: .horizontal,
                backgroundDisplayMode: .icon,
                title: "Title",
                isSensitive: false,
                hasThumbnail: false,
                description: { _ in ""},
                type: .node,
                properties: [],
                thumbnailImageData: { Data() },
                swipeActions: { _ in [] }
            ),
            rowAssets: .example,
            colorAssets: .example,
            previewContent: .example,
            actions: .init(contextAction: { _ in }, selectionAction: { }, previewTapAction: { }),
            swipeActions: []
        )
    }

    private func assertChangeSortOrder(
        with sortOrder: Search.SortOrderEntity,
        expectedReceivedQueries: [SearchQuery]? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let harness = Harness(self)
        let changeSortOrderTask = harness.sut.changeSortOrder(sortOrder)
        await changeSortOrderTask.value
        let defaultExpectedReceivedQueries: [SearchQuery] = [
            .userSupplied(
                .init(
                    query: "",
                    sorting: sortOrder,
                    mode: .home,
                    isSearchActive: false,
                    chips: []
                )
            )
        ]

        let expectedSearchQueries = (expectedReceivedQueries != nil
        ? expectedReceivedQueries
        : defaultExpectedReceivedQueries) ?? []

        XCTAssertEqual(
            harness.resultsProvider.passedInQueries,
            expectedSearchQueries,
            """
                Expected search queries \(expectedSearchQueries)
                but received \(harness.resultsProvider.passedInQueries)
            """,
            file: file,
            line: line
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
