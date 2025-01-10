@preconcurrency import Combine
import MEGAFoundation
import MEGASwift
import MEGATest
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
    @MainActor static let deselectedColor = SearchConfig.testConfig.chipAssets.normalBackground
    @MainActor static let selectedColor = SearchConfig.testConfig.chipAssets.selectedBackground
}

final class SearchResultsViewModelTests: XCTestCase, @unchecked Sendable {
    @MainActor
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
        
        init(_ testcase: XCTestCase,
             searchResultUpdateSignalSequence: AnyAsyncSequence<SearchResultUpdateSignal> = EmptyAsyncSequence().eraseToAnyAsyncSequence()) {
            self.testcase = testcase
            resultsProvider = MockSearchResultsProviding(
                searchResultUpdateSignalSequence: searchResultUpdateSignalSequence)
            
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
                viewDisplayMode: .unknown,
                isSearchByNodeDescriptionFeatureEnabled: true
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
        func withChipsPrepared(chipTypes: [SearchChipEntity.ChipType] = [.nodeFormat(.photo)]) -> Self {
            let results = SearchResultsEntity(
                results: [],
                availableChips: chipTypes.enumerated().map { .init(type: $0.element, title: "chip_\($0.offset)")},
                appliedChips: []
            )
            
            resultsProvider.resultFactory = { _ in
                return results
            }
            
            return self
        }
        
        @discardableResult
        func noResultsWithSingleChipApplied(chipType: SearchChipEntity.ChipType = .nodeFormat(.photo)) -> Self {
            resultsProvider.resultFactory = { _ in
                let results = SearchResultsEntity(
                    results: [],
                    availableChips: [.init(type: chipType, title: "appliedChip")],
                    appliedChips: [.init(type: chipType, title: "appliedChip")]
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
    
    @MainActor
    func testListItems_onStart_hasNoItemsAndSingleChipShown() async {
        let harness = Harness(self)
        harness.resultsProvider.resultFactory = { _ in
            .resultWithNoItemsAndSingleChip
        }
        await harness.sut.task()
        XCTAssertTrue(harness.sut.listItems.isEmpty)
        XCTAssertEqual(harness.sut.chipsItems.map(\.id), ["chip_2"])
    }
    
    @MainActor
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
    
    @MainActor
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
                query: { nil },
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
                    unselectedBorderColor: .gray,
                    selectedBorderColor: .green,
                    titleTextColor: Color.primary,
                    subtitleTextColor: Color.secondary,
                    nodeDescriptionTextNormalColor: Color.secondary,
                    vibrantColor: .red,
                    resultPropertyColor: .gray,
                    verticalThumbnailFooterText: .white,
                    verticalThumbnailFooterBackground: .black,
                    verticalThumbnailPreviewBackground: .gray,
                    verticalThumbnailTopIconsBackground: .white.opacity(0.4),
                    listRowSeparator: .gray,
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
    func testListItems_whenReAppear_shouldRefreshResults() async {
        // given
        let harness = Harness(self).withResultsPrepared(count: 5, startingId: 1)
        await harness.sut.task()
        harness.resetResultFactory()
        XCTAssertEqual(harness.sut.listItems.map { $0.result.id }, [1, 2, 3, 4, 5])
        XCTAssertEqual(harness.sut.listItems.map { $0.result.title }, ["1", "2", "3", "4", "5"])
        harness.prepareRefreshedResults(startId: 4, endId: 7)
        
        // when
        await harness.sut.task()
        
        // then
        XCTAssertEqual(harness.sut.listItems.map { $0.result.id }, [4, 5, 6, 7])
        XCTAssertEqual(harness.sut.listItems.map { $0.result.title }, ["refreshed 4", "refreshed 5", "refreshed 6", "refreshed 7"])
    }
    
    @MainActor
    func testOnSelectionAction_passesSelectedResultViaBridge() async throws {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.queryChanged(to: "query", isSearchActive: true)
        let item = try XCTUnwrap(harness.sut.listItems.first)
        item.actions.selectionAction()
        XCTAssertEqual(harness.selectedResults, [.resultSelectionWith(id: 1, title: "title")])
    }
    
    @MainActor
    func testOnContextAction_passesSelectedResultViaBridge() async throws {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.queryChanged(to: "query", isSearchActive: true)
        let item = try XCTUnwrap(harness.sut.listItems.first)
        item.actions.contextAction(UIButton())
        XCTAssertEqual(harness.contextTriggeredResults, [.resultWith(id: 1, title: "title")])
    }
    
    @MainActor
    func testListItems_showResultsTitleAndDescription() async {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.queryChanged(to: "query", isSearchActive: true)
        let result = harness.resultVM(at: 0)
        XCTAssertEqual(result.title, "title".forceLeftToRight())
        XCTAssertEqual(result.result.description(.list), "Desc")
    }

    @MainActor
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

    @MainActor
    func testChipItems_byDefault_noChipsSelected() async {
        let harness = Harness(self).withChipsPrepared(chipTypes: [
            .nodeFormat(.photo),
            .nodeFormat(.audio),
            .nodeFormat(.pdf),
            .nodeFormat(.presentation)
        ])
        await harness.sut.task()
        let allDeselected = harness.sut.chipsItems.allSatisfy {
            $0.pill.background == .deselectedColor
        }
        XCTAssertTrue(allDeselected)
    }
    
    @MainActor
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
    
    @MainActor
    func testEmptyView_isNil_whenItemsNotEmpty() async {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.queryChanged(to: "query", isSearchActive: true)
        XCTAssertNil(harness.sut.emptyViewModel)
    }
    
    @MainActor
    func testEmptyView_notNil_whenItemsEmpty() async throws {
        let harness = Harness(self)
        await harness.sut.queryChanged(to: "query", isSearchActive: true)
        let contentUnavailableVM = try XCTUnwrap(harness.sut.emptyViewModel)
        let expectedContent = SearchConfig.EmptyViewAssets.testAssets
        XCTAssertEqual(contentUnavailableVM.image, expectedContent.image)
        XCTAssertEqual(contentUnavailableVM.title, expectedContent.title)
    }
    
    @MainActor
    func testEmptyView_isDefault_whenChipSelected_AndQueryNotEmpty() async throws {
        let harness = Harness(self).withChipsPrepared(chipTypes: [
            .nodeFormat(.photo),
            .nodeFormat(.audio)
        ])
        await harness.sut.queryChanged(to: "query", isSearchActive: true)
        await harness.sut.chipsItems.first!.select()
        _ = try XCTUnwrap(harness.sut.emptyViewModel)
        let content: Harness.EmptyContent = .init(chip: nil, isSearchActive: true)
        XCTAssertEqual(harness.emptyContentRequested, [content, content])
    }

    @MainActor
    func testEmptyView_isContextualBasedOnChip_whenChipSelected_AndQueryEmpty() async throws {
        let harness = Harness(self)
        await harness.sut.queryChanged(to: "", isSearchActive: false)
        harness.noResultsWithSingleChipApplied()
        await harness.sut.chipsItems.first!.select()
        _ = try XCTUnwrap(harness.sut.emptyViewModel)
        let content: [Harness.EmptyContent] = [
            .init(chip: nil, isSearchActive: false),
            .init(
                chip: .some(.init(type: SearchChipEntity.ChipType.nodeFormat(.photo), title: "appliedChip")),
                isSearchActive: false
            )
        ]
        XCTAssertEqual(harness.emptyContentRequested, content)
    }

    @MainActor
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
    
    @MainActor
    func testScrolled_callsBridgeResignKeyboard() {
        let harness = Harness(self)
        harness.sut.scrolled()
        XCTAssertEqual(harness.keyboardResignedCount, 1)
    }
    
    @MainActor
    func testSelectAll_whenNoNodesAreSelected_shouldSelectAllNodes() {
        let currentNodes: [ResultId] = [1, 2, 3, 4]
        let harness = Harness(self).withSelectedNodes([], currentResults: currentNodes)
        harness.sut.listItems = Array(1...4).map { generateRandomSearchResultRowViewModel(id: $0) }
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
    
    @MainActor
    func testSelectAll_whenSomeNodesAreSelected_shouldSelectAllNodes() {
        let currentNodes: [ResultId] = [1, 2, 3, 4]
        let harness = Harness(self).withSelectedNodes([1, 2], currentResults: currentNodes)
        harness.sut.listItems = Array(1...4).map { generateRandomSearchResultRowViewModel(id: $0) }
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
    
    @MainActor
    func testSelectAll_whenAllNodesAreSelected_shouldDeselectAllNodes() {
        let currentNodes: [ResultId] = [1, 2, 3, 4]
        let harness = Harness(self).withSelectedNodes(currentNodes, currentResults: currentNodes)
        harness.resultsProvider.currentResultIdsToReturn = [1, 2, 3, 4]
        harness.sut.selectedResultIds = [1, 2, 3, 4]
        harness.sut.selectedRowIds = Set(Array(1...4).map { generateRandomSearchResultRowViewModel(id: $0).id })
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

    @MainActor
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

    @MainActor
    func testReloadResults_whenPerformed_shouldReturnExpectedQueries() async {
        let harness = Harness(self).withSingleResultPrepared()
        await harness.sut.reloadResults()
        let expectedReceivedQueries: [SearchQuery] = [
            .initial
        ]
        XCTAssertEqual(harness.resultsProvider.passedInQueries, expectedReceivedQueries)
    }
    
    @MainActor
    func disable_testOnSearchResultsUpdated_whenGenericUpdate_shouldReturnExpectedResults() async {
        // given
        let (stream, continuation) = AsyncStream.makeStream(of: SearchResultUpdateSignal.self)
        let harness = Harness(self, searchResultUpdateSignalSequence: stream.eraseToAnyAsyncSequence())
            .withResultsPrepared(count: 10) // Initially there are 10 results
        
        let initialSearchExp = expectation(description: "Wait for the initial update")
        let updateExp = expectation(description: "Wait for the list to update")
        let cancellable = harness.sut.$listItems
            .sink { results in
                let resultIds = results.map({ $0.result.id })
                if resultIds == Array(1...10) {
                    initialSearchExp.fulfill()
                } else if resultIds == Array(1...15) {
                    updateExp.fulfill()
                }
            }
        trackTaskCancellation {
            await harness.sut.task()
        }
        
        await fulfillment(of: [initialSearchExp], timeout: 1.0)
        
        harness.resetResultFactory()
        harness.prepareRefreshedResults(startId: 1, endId: 15) // After refreshing, there will be 15 results
        
        // when
        continuation.yield(.generic)
        
        await fulfillment(of: [updateExp], timeout: 1.0)
        // then
        XCTAssertEqual(harness.sut.listItems.map { $0.result.id }, Array(1...15))
        cancellable.cancel()
        continuation.finish()
    }
    
    @MainActor
    func testOnSearchResultsUpdated_whenSpecificUpdate_shouldReturnExpectedResults() async {
        // given
        let (stream, continuation) = AsyncStream.makeStream(of: SearchResultUpdateSignal.self)
        let harness = Harness(self, searchResultUpdateSignalSequence: stream.eraseToAnyAsyncSequence())
            .withResultsPrepared(count: 10)
        
        XCTAssertTrue(harness.sut.listItems.isEmpty)
        
        let listItemsExpectation = expectation(description: "Wait for the listItems to be updated")
        let cancellable = harness.sut.$listItems.first(where: { $0.count == 10 }).sink { _ in
            listItemsExpectation.fulfill()
        }
        
        trackTaskCancellation {
            await harness.sut.task()
        }
        
        await fulfillment(of: [listItemsExpectation], timeout: 1)
        
        cancellable.cancel()
        
        let thumbnailImage1 = UIImage(systemName: "square.and.arrow.up.fill")!.pngData()!
        let thumbnailImage2 = UIImage(systemName: "pencil.circle.fill")!.pngData()!
        let thumbnailImage3 = UIImage(systemName: "pencil.tip")!.pngData()!

        let exp = expectation(description: "Wait for the images to be updated")
        exp.expectedFulfillmentCount = 2

        let cancellable1 = harness.sut.listItems[0].$thumbnailImage.sink { image in
            if image.pngData()?.count == thumbnailImage1.count {
                exp.fulfill()
            }
        }

        let cancellable2 = harness.sut.listItems[1].$thumbnailImage.sink { image in
            if image.pngData()?.count == thumbnailImage2.count {
                exp.fulfill()
            }
        }

        let updatedResult1 = SearchResult.resultWith(id: 1, thumbnailImageData: thumbnailImage1)
        let updatedResult2 = SearchResult.resultWith(id: 2, thumbnailImageData: thumbnailImage2)
        let updatedResult100 = SearchResult.resultWith(id: 100, thumbnailImageData: thumbnailImage3)

        continuation.yield(.specific(result: updatedResult1)) // Triggers item update
        continuation.yield(.specific(result: updatedResult2)) // Triggers item updates
        continuation.yield(.specific(result: updatedResult100)) // Not triggering item update
        continuation.finish()
        
        await fulfillment(of: [exp], timeout: 2.0)
        cancellable1.cancel()
        cancellable2.cancel()
    }

    @MainActor
    func testSelectedRows_whenMultipleRowsSelected_shouldMatchResultsIds() {
        let harness = Harness(self)
        
        harness.sut.listItems = Array(1...10).map { generateRandomSearchResultRowViewModel(id: $0) }
        
        let selectedRows: Set<SearchResultRowViewModel.ID> = Set(harness.sut.listItems.prefix(5).map(\.id))
        
        let exp = expectation(description: "Wait for selected results")
        let selectedResultsSubscription = harness
            .sut
            .$selectedResultIds
            .sink { results in
                if results == Set(1...5) {
                    exp.fulfill()
                }
            }

        harness.sut.selectedRowIds = selectedRows
        wait(for: [exp], timeout: 1.0)
        selectedResultsSubscription.cancel()
    }
    
    @MainActor
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
        
        await Task.yield()
        
        // then
        XCTAssertEqual(harness.sut.listItems.map { $0.result.id }, Array(1...150)) // 50 more results loaded, hence 150 in total
    }

    @MainActor
    func testSelectedRowsCount_whenSelectedAll_shouldMatchTheResult() {
        let harness = makeHarnessWithAllItemsSelected(listItemCount: 10)
        XCTAssertEqual(harness.sut.selectedResultsCount, 10)
    }

    @MainActor
    func testClearSelection_whenInvoked_shouldClearSelection() async {
        let harness = makeHarnessWithAllItemsSelected(listItemCount: 10)
        XCTAssertEqual(harness.sut.selectedResultsCount, 10)

        // There is a throttle that is setup for the "selectedRowIds" of 0.4 seconds
        // This throttle might effect results of `clearSelection` (triggered by "toggleSelectAll()" - previous call)
        // Hence waiting for 0.6 seconds before triggering
        try? await Task.sleep(nanoseconds: 600_000_000)

        harness.sut.clearSelection()
        XCTAssertEqual(harness.sut.selectedResultsCount, 0)
    }

    @MainActor
    func testNodeDescription_whenEmpty_shouldReturnNil() async {
        let harness = generateRandomSearchResultRowViewModel(id: 1)
        XCTAssertNil(harness.note)
    }

    @MainActor
    func testNodeDescription_whenQueryIsNil_shouldReturnNil() async {
        let harness = generateRandomSearchResultRowViewModel(id: 1, note: "foo", query: { nil })
        XCTAssertNil(harness.note)
    }

    @MainActor
    func testNodeDescription_whenDescriptionIsNilAndQueryIsNotEmpty_shouldReturnNil() async {
        let harness = generateRandomSearchResultRowViewModel(id: 1, note: nil, query: { "test" })
        XCTAssertNil(harness.note)
    }

    @MainActor
    func testNodeDescription_whenDescriptionIsNotEmptyAndQueryIsAlsoNotEmpty_shouldReturnNil() async {
        let harness = generateRandomSearchResultRowViewModel(id: 1, note: "This is test", query: { "test" })
        XCTAssertEqual(harness.note, "This is test")
    }

    @MainActor
    private func makeHarnessWithAllItemsSelected(listItemCount count: Int) -> Harness {
        let harness = Harness(self)
        let listItems = Array(1...count).map { generateRandomSearchResultRowViewModel(id: $0) }
        harness.resultsProvider.currentResultIdsToReturn = listItems.map { $0.result.id }
        harness.sut.listItems = listItems
        harness.sut.toggleSelectAll()
        return harness
    }

    @MainActor
    private func generateRandomSearchResultRowViewModel(
        id: Int,
        note: String? = nil,
        query: @escaping () -> String? = { nil }
    ) -> SearchResultRowViewModel {
        .init(
            result: .init(
                id: UInt64(id),
                thumbnailDisplayMode: .horizontal,
                backgroundDisplayMode: .icon,
                title: "Title",
                note: note,
                isSensitive: false,
                hasThumbnail: false,
                description: { _ in ""},
                type: .node,
                properties: [],
                thumbnailImageData: { Data() },
                swipeActions: { _ in [] }
            ),
            query: query,
            rowAssets: .example,
            colorAssets: .example,
            previewContent: .example,
            actions: .init(contextAction: { _ in }, selectionAction: { }, previewTapAction: { }),
            swipeActions: []
        )
    }

    @MainActor
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
