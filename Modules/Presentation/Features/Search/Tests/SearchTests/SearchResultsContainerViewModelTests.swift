import MEGASwift
import MEGAUIKit
@testable import Search
import SearchMock
import SwiftUI
import Testing
import UIKit

@MainActor
struct SearchResultsContainerViewModelTests {

    @Test func testInit() {
        let sut = makeSUT()
        #expect(sut.chipsItems.isEmpty)
        #expect(sut.presentedChipsPickerViewModel == nil)
        #expect(sut.showChips == false)
        #expect(sut.showSorting == false)
        #expect(sut.showSortSheet == false)
    }

    @Test func testColorAssets_whenInvoked_shouldMatchTheTestConfigAssets() {
        let sut = makeSUT()
        let expectedColorAssets = SearchConfig.testConfig.colorAssets
        #expect(sut.colorAssets.unselectedBorderColor == expectedColorAssets.unselectedBorderColor)
        #expect(sut.colorAssets.selectedBorderColor == expectedColorAssets.selectedBorderColor)
        #expect(sut.colorAssets.titleTextColor == expectedColorAssets.titleTextColor)
        #expect(sut.colorAssets.subtitleTextColor == expectedColorAssets.subtitleTextColor)
        #expect(sut.colorAssets.nodeDescriptionTextNormalColor == expectedColorAssets.nodeDescriptionTextNormalColor)
        #expect(sut.colorAssets.tagsTextColor == expectedColorAssets.tagsTextColor)
        #expect(sut.colorAssets.textHighlightColor == expectedColorAssets.textHighlightColor)
        #expect(sut.colorAssets.vibrantColor == expectedColorAssets.vibrantColor)
        #expect(sut.colorAssets.resultPropertyColor == expectedColorAssets.resultPropertyColor)
        #expect(sut.colorAssets.verticalThumbnailFooterText == expectedColorAssets.verticalThumbnailFooterText)
        #expect(sut.colorAssets.verticalThumbnailFooterBackground == expectedColorAssets.verticalThumbnailFooterBackground)
        #expect(sut.colorAssets.verticalThumbnailPreviewBackground == expectedColorAssets.verticalThumbnailPreviewBackground)
        #expect(sut.colorAssets.verticalThumbnailTopIconsBackground == expectedColorAssets.verticalThumbnailTopIconsBackground)
        #expect(sut.colorAssets.listRowSeparator == expectedColorAssets.listRowSeparator)
        #expect(sut.colorAssets.checkmarkBackgroundTintColor == expectedColorAssets.checkmarkBackgroundTintColor)
        #expect(sut.colorAssets.listHeaderTextColor == expectedColorAssets.listHeaderTextColor)
        #expect(sut.colorAssets.listHeaderBackgroundColor == expectedColorAssets.listHeaderBackgroundColor)
    }

    @Test func testChipAssets_whenInvoked_shouldMatchTheTestConfigAssets() {
        let sut = makeSUT()
        let expectedChipAssets = SearchConfig.testConfig.chipAssets
        #expect(sut.chipAssets.selectionIndicatorImage == expectedChipAssets.selectionIndicatorImage)
        #expect(sut.chipAssets.closeIcon == expectedChipAssets.closeIcon)
        #expect(sut.chipAssets.selectedForeground == expectedChipAssets.selectedForeground)
        #expect(sut.chipAssets.selectedBackground == expectedChipAssets.selectedBackground)
        #expect(sut.chipAssets.normalForeground == expectedChipAssets.normalForeground)
        #expect(sut.chipAssets.normalBackground == expectedChipAssets.normalBackground)
    }

    @Test func testHeaderViewModel_whenButtonPressed_shouldShowSortSheet() {
        let sut = makeSUT(sortOptionsViewModel: .init(
            title: "Sort by",
            sortOptions: [
                .init(sortOrder: .init(key: .name), title: "Name", iconsByDirection: [:]),
                .init(sortOrder: .init(key: .name, direction: .descending), title: "Name", iconsByDirection: [:])
            ]
        ))
        sut.headerViewModel?.handler()
        #expect(sut.showSortSheet == true)
    }

    @Test func testTask_whenInvoked_shouldMatchThePassedInQueries() async {
        let resultsProvider = MockSearchResultsProviding(
            searchResultUpdateSignalSequence: EmptyAsyncSequence().eraseToAnyAsyncSequence()
        )
        resultsProvider.resultFactory = { _ in
            SearchResultsEntity(
                results: [
                    .resultWith(id: 1, title: "title")
                ],
                availableChips: [],
                appliedChips: []
            )
        }
        let sut = makeSUT(resultsProvider: resultsProvider)
        await sut.task()
        await sut.searchResultsViewModel.queryChanged(to: "query", isSearchActive: true)
        let expectedReceivedQueries: [SearchQuery] = [
            .initial,
            .userSupplied(.query("query", isSearchActive: true))
        ]
        #expect(resultsProvider.passedInQueries == expectedReceivedQueries)
    }

    @Test func testShowChipsGroupPicker_whenInvoked_shouldPresentTheChipsOptionsView() {
        let sut = makeSUT()
        sut.chipsItems = [
            .init(
                id: "type",
                pill: .init(title: "", selected: false, icon: .none, config: SearchConfig.testConfig.chipAssets),
                select: {}
            ),
            .init(
                id: "Modified Date",
                pill: .init(title: "", selected: false, icon: .none, config: SearchConfig.testConfig.chipAssets),
                select: {}
            )
        ]
        sut.showChipsGroupPicker(with: "type")
        #expect(sut.presentedChipsPickerViewModel?.id == sut.chipsItems.first?.id)
    }

    @Test func testDismissChipGroupPicker_whenInvoked_shouldHideTheChipsOptionsView() async {
        let sut = makeSUT()
        sut.chipsItems = [
            .init(
                id: "type",
                pill: .init(title: "", selected: false, icon: .none, config: SearchConfig.testConfig.chipAssets),
                select: {}
            ),
            .init(
                id: "Modified Date",
                pill: .init(title: "", selected: false, icon: .none, config: SearchConfig.testConfig.chipAssets),
                select: {}
            )
        ]
        sut.showChipsGroupPicker(with: "type")
        await sut.dismissChipGroupPicker()
        #expect(sut.presentedChipsPickerViewModel == nil)
    }

    @Test func testSelectSortOption_whenInvoked_ShouldHideSortSheet() throws {
        let sut = makeSUT(
            sortOptionsViewModel: .init(
                title: "Sort by",
                sortOptions: [
                    .init(sortOrder: .init(key: .name), title: "Name", iconsByDirection: [:]),
                    .init(sortOrder: .init(key: .name, direction: .descending), title: "Name", iconsByDirection: [:])
                ]
            )
        )
        sut.showSortSheet = true
        let selectedSortOption = try #require(sut.displaySortOptionsViewModel.sortOptions.last)
        sut.displaySortOptionsViewModel.tapHandler?(selectedSortOption)
        #expect(sut.showSortSheet == false)
    }

    @Test func testSelectSearchResults_whenInvoked_shouldSwitchToEditingMode() {
        let sut = makeSUT()
        sut.selectSearchResults([SearchResult.resultWith(id: 101, title: "A")])
        #expect(sut.searchResultsViewModel.editing)
    }

    @Test func testQueryChanged_shouldRemoveChips_whenShowChipsIsDisabled() async {
        let (sut, resultsProvider) = makeSUTWithChipsPrepared(chipTypes: [
            .nodeFormat(.photo),
            .nodeFormat(.audio),
            .nodeFormat(.pdf),
            .nodeFormat(.presentation)
        ])
        await sut.task()
        await sut.chipsItems.first!.select()
        await sut.searchResultsViewModel.queryChanged(to: "test", isSearchActive: true)
        let expectedReceivedQueries: [SearchQuery] = [
            .initial,
            .userSupplied(
                .init(
                    query: "",
                    sorting: .init(key: .name),
                    mode: .home,
                    isSearchActive: false,
                    chips: [.init(type: .nodeFormat(.photo), title: "chip_0", icon: nil, subchipsPickerTitle: nil, subchips: [])]
                )
            ),
            .userSupplied(
                .init(
                    query: "test",
                    sorting: .init(key: .name),
                    mode: .home,
                    isSearchActive: true,
                    chips: []
                )
            )
        ]
        #expect(resultsProvider.passedInQueries == expectedReceivedQueries)
    }

    @Test func testChipItems_byDefault_noChipsSelected() async {
        let (sut, _) = makeSUTWithChipsPrepared(chipTypes: [
            .nodeFormat(.photo),
            .nodeFormat(.audio),
            .nodeFormat(.pdf),
            .nodeFormat(.presentation)
        ])
        await sut.task()
        let allDeselected = sut.chipsItems.allSatisfy {
            $0.pill.background == SearchConfig.testConfig.chipAssets.normalBackground
        }
        #expect(allDeselected)
    }

    @Test func testChipItems_appliedChips_isSelected() async {
        let searchResults = SearchResultsEntity(
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

        let resultsProvider = MockSearchResultsProviding(
            searchResultUpdateSignalSequence: EmptyAsyncSequence().eraseToAnyAsyncSequence()
        )
        resultsProvider.resultFactory = { _ in
            searchResults
        }

        let sut = makeSUT(resultsProvider: resultsProvider)
        await sut.task()
        let selectedChipItems = sut.chipsItems.filter {
            $0.pill.background == SearchConfig.testConfig.chipAssets.selectedBackground
        }
        let expectedIds = [searchResults.appliedChips.first!.id]
        #expect(selectedChipItems.map(\.id) == expectedIds)
    }

    @Test(arguments: [
        (SortOrderEntity(key: .name), [SearchQuery.initial]),
        (SortOrderEntity(key: .name, direction: .descending), nil),
        (SortOrderEntity(key: .size, direction: .descending), nil),
        (SortOrderEntity(key: .size), nil),
        (SortOrderEntity(key: .dateAdded, direction: .descending), nil),
        (SortOrderEntity(key: .dateAdded), nil),
        (SortOrderEntity(key: .label), nil),
        (SortOrderEntity(key: .label, direction: .descending), nil),
        (SortOrderEntity(key: .favourite), nil),
        (SortOrderEntity(key: .favourite, direction: .descending), nil)
    ])
    func testChangeSortOrder_forAllCases_shouldMatchTheExpectation(
        sortOrder: Search.SortOrderEntity,
        expectedReceivedQueries: [SearchQuery]?
    ) async {
        let (sut, resultsProvider) = makeSUTWithChipsPrepared()
        await sut.task()
        let changeSortOrderTask = sut.changeSortOrder(sortOrder)
        await changeSortOrderTask.value
        let defaultExpectedReceivedQueries: [SearchQuery] = [
            .initial,
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

        #expect(resultsProvider.passedInQueries == expectedSearchQueries)
    }

    @Test func testShowChipsInitialValue_whenSet_ShouldMatchResult() {
        let sut = makeSUT(showChips: true)
        #expect(sut.showChips)
    }

    @Test func testSetSearchChipsVisible_whenSetWithoutAnimation_shouldShowChips() {
        let sut = makeSUT(showChips: false)
        sut.setSearchChipsVisible(true, animated: false)
        #expect(sut.showChips)
    }

    @Test func testSetSearchChipsVisible_whenSetWithAnimation_shouldShowChips() {
        let sut = makeSUT(showChips: false)
        sut.setSearchChipsVisible(true, animated: true)
        #expect(sut.showChips)
    }

    @Test func testDisplaySortOptionsViewModel_whenDisplayed_shouldOmitSelectedSortOption() throws {
        let sortOptionsViewModel = SearchResultsSortOptionsViewModel(
            title: "Sort by",
            sortOptions: [
                .init(sortOrder: .init(key: .name), title: "Name", iconsByDirection: [:]),
                .init(sortOrder: .init(key: .name, direction: .descending), title: "Name", iconsByDirection: [:])
            ]
        )
        let sut = makeSUT(sortOptionsViewModel: sortOptionsViewModel)
        let displaySortOptionsViewModel = sut.displaySortOptionsViewModel
        #expect(displaySortOptionsViewModel.title == "Sort by")
        #expect(displaySortOptionsViewModel.sortOptions.count == 1)
        let sortOption = try #require(displaySortOptionsViewModel.sortOptions.first)
        #expect(sortOption.sortOrder == .init(key: .name, direction: .descending))
    }

    @Test func testHeaderViewModel_whenDisplayed_shouldShowSelectedSortOption() throws {
        let iconByDirection: [SortOrderEntity.Direction: Image] = [
            .ascending: Image(systemName: "plus"),
            .descending: Image(systemName: "minus")
        ]
        let sortOptionsViewModel = SearchResultsSortOptionsViewModel(
            title: "Sort by",
            sortOptions: [
                .init(sortOrder: .init(key: .name), title: "Name", iconsByDirection: iconByDirection),
                .init(sortOrder: .init(key: .name, direction: .descending), title: "Name", iconsByDirection: iconByDirection)
            ]
        )
        let sut = makeSUT(sortOptionsViewModel: sortOptionsViewModel)
        let headerViewModel = try #require(sut.headerViewModel)
        #expect(headerViewModel.title == "Name")
        #expect(headerViewModel.icon == Image(systemName: "plus"))
    }

    @Test func testUpdateQuery_whenChipsAreDisabled_shouldClearChips() async {
        let sut = makeSUT(showChips: false)
        let updatedQuery = await sut.updateQuery(
            .userSupplied(
                .init(
                    query: "test",
                    sorting: .init(key: .dateAdded, direction: .ascending),
                    mode: .home,
                    isSearchActive: false,
                    chips: [.init(type: .nodeFormat(.document), title: "Docs")]
                )
            )
        )
        #expect(updatedQuery.chips == [])
    }

    @Test func testUpdateQuery_whenChipsAreEnabled_shouldUpdateSortingOrder() async {
        let sut = makeSUT(showChips: true)
        let updatedQuery = await sut.updateQuery(
            .userSupplied(
                .init(
                    query: "test",
                    sorting: .init(key: .dateAdded, direction: .ascending),
                    mode: .home,
                    isSearchActive: false,
                    chips: [.init(type: .nodeFormat(.document), title: "Docs")]
                )
            )
        )
        #expect(updatedQuery.sorting == .init(key: .name))
    }

    @Test func testSelectedResultsCount_whenToggleSelectAll_shouldSelectTheItem() async {
        let results = SearchResultsEntity(
            results: [
                .resultWith(id: 1, title: "title")
            ],
            availableChips: [],
            appliedChips: []
        )

        let resultsProvider = MockSearchResultsProviding(
            searchResultUpdateSignalSequence: EmptyAsyncSequence().eraseToAnyAsyncSequence()
        )
        resultsProvider.currentResultIdsToReturn = [1]
        resultsProvider.resultFactory = { _ in
            results
        }

        let sut = makeSUT(resultsProvider: resultsProvider)
        await sut.task()
        sut.toggleSelectAll()
        #expect(sut.selectedResultsCount == 1)
    }

    @Test func testPageLayout_whenUpdated_shouldUpdateTheLayout() {
        let sut = makeSUT()
        sut.update(pageLayout: .thumbnail)
        #expect(sut.searchResultsViewModel.layout == .thumbnail)
    }

    @Test func testEditing_whenSetToTrue_shouldReturnEditingToTrue() {
        let sut = makeSUT()
        sut.setEditing(true)
        #expect(sut.searchResultsViewModel.editing)
    }

    @Test func testClearSelection() async {
        let results = SearchResultsEntity(
            results: [
                .resultWith(id: 1, title: "title")
            ],
            availableChips: [],
            appliedChips: []
        )

        let resultsProvider = MockSearchResultsProviding(
            searchResultUpdateSignalSequence: EmptyAsyncSequence().eraseToAnyAsyncSequence()
        )
        resultsProvider.currentResultIdsToReturn = [1]
        resultsProvider.resultFactory = { _ in
            results
        }

        let sut = makeSUT(resultsProvider: resultsProvider)
        await sut.task()
        sut.toggleSelectAll()
        sut.clearSelection()
        #expect(sut.searchResultsViewModel.selectedResultIds == [])
        #expect(sut.searchResultsViewModel.selectedRowIds == [])
    }

    typealias SUT = SearchResultsContainerViewModel
    private func makeSUT(
        sortOptionsViewModel: SearchResultsSortOptionsViewModel = .init(title: "", sortOptions: []),
        resultsProvider: some SearchResultsProviding = MockSearchResultsProviding(
            searchResultUpdateSignalSequence: EmptyAsyncSequence().eraseToAnyAsyncSequence()
        ),
        showChips: Bool = false
    ) -> SUT {
        let selection: (SearchResultSelection) -> Void = { _ in }
        let context: (SearchResult, UIButton) -> Void = { _, _ in }
        let chipTapped: (SearchChipEntity, Bool) -> Void = { _, _ in }

        let bridge = SearchBridge(
            selection: { selection($0) },
            context: { context($0, $1) },
            chipTapped: { chipTapped($0, $1) },
            sortingOrder: { .init(key: .name) },
            updateSortOrder: { _ in }
        )

        let askedForEmptyContent: (SearchChipEntity?, SearchQuery) -> SearchConfig.EmptyViewAssets = {
            SearchConfig.testConfig.emptyViewAssetFactory($0, $1)
        }

        let testConfig = SearchConfig.testConfig
        let config = SearchConfig(
            chipAssets: testConfig.chipAssets,
            emptyViewAssetFactory: { chip, query in
                askedForEmptyContent(chip, query)
            },
            rowAssets: testConfig.rowAssets,
            colorAssets: testConfig.colorAssets,
            contextPreviewFactory: testConfig.contextPreviewFactory
        )

        return .init(
            bridge: bridge,
            config: testConfig,
            searchResultsViewModel: .init(
                resultsProvider: resultsProvider,
                bridge: bridge,
                config: config,
                layout: .list,
                showLoadingPlaceholderDelay: 0.1,
                keyboardVisibilityHandler: MockKeyboardVisibilityHandler(),
                viewDisplayMode: .unknown,
                listHeaderViewModel: nil,
                isSelectionEnabled: true
            ),
            sortOptionsViewModel: sortOptionsViewModel,
            showChips: showChips
        )
    }

    func makeSUTWithChipsPrepared(
        chipTypes: [SearchChipEntity.ChipType] = [.nodeFormat(.photo)]
    ) -> (SUT, MockSearchResultsProviding) {
        let resultsProvider = MockSearchResultsProviding(
            searchResultUpdateSignalSequence: EmptyAsyncSequence().eraseToAnyAsyncSequence()
        )

        let results = SearchResultsEntity(
            results: [],
            availableChips: chipTypes.enumerated().map { .init(type: $0.element, title: "chip_\($0.offset)")},
            appliedChips: []
        )

        resultsProvider.resultFactory = { _ in
            return results
        }

        return (makeSUT(resultsProvider: resultsProvider), resultsProvider)
    }
}
