@testable import Search
import Testing

@MainActor
struct SearchResultsHeaderSortViewViewModelTests {
    @Test func testSelectionChanged_whenChanged_shouldDismissSheetAndChangeSelection() {
        let sortTitle = "Sort By"
        let sortOptions: [SearchResultsSortOption] = [
            .init(sortOrder: .init(key: .name), title: "Name", iconsByDirection: [:]),
            .init(sortOrder: .init(key: .name, direction: .descending), title: "Name", iconsByDirection: [:]),
            .init(sortOrder: .init(key: .dateAdded), title: "Name", iconsByDirection: [:])

        ]
        let sut = SearchResultsHeaderSortViewViewModel(
            selectedOption: .init(sortOrder: .init(key: .name), title: "Name", iconsByDirection: [:]),
            displaySortOptionsViewModel: .init(title: sortTitle, sortOptions: sortOptions)
        )

        #expect(sut.selectedOption.sortOrder.key == .name)
        #expect(sut.showSortSheet == false)
        #expect(sut.displaySortOptionsViewModel.title == sortTitle)
        #expect(sut.displaySortOptionsViewModel.sortOptions.count == 3)
        let expectedSortOrder: [SortOrderEntity] = [
            .init(key: .name),
            .init(key: .name, direction: .descending),
            .init(key: .dateAdded)
        ]
        #expect(sut.displaySortOptionsViewModel.sortOptions.map(\.sortOrder) == expectedSortOrder)

        // show the sheet and change the selection
        sut.showSortSheet = true
        sut.selectionChanged(to: .init(sortOrder: .init(key: .dateAdded), title: "Date Added", iconsByDirection: [:]))

        #expect(sut.selectedOption.sortOrder.key == .dateAdded)
        #expect(sut.showSortSheet == false)
    }

    @Test func testChangeSelection_withSingleSortOptions_shouldNotShowTheSortSheet() {
        let sortTitle = "Sort By"
        let sortOptions: [SearchResultsSortOption] = [
            .init(sortOrder: .init(key: .lastModified, direction: .descending), title: "Last Modified", iconsByDirection: [:])
        ]

        var resultSortOption: SearchResultsSortOption?
        let sut = SearchResultsHeaderSortViewViewModel(
            selectedOption: sortOptions[0],
            displaySortOptionsViewModel: .init(title: sortTitle, sortOptions: sortOptions) { selectedSortOption in
                resultSortOption = selectedSortOption
            }
        )

        sut.changeSelection()
        #expect(resultSortOption?.sortOrder == sortOptions[0].sortOrder)
    }

    @Test func testChangeSelection_withMultipleSortOptions_shouldShowTheSortSheet() {
        let sortTitle = "Sort By"
        let sortOptions: [SearchResultsSortOption] = [
            .init(sortOrder: .init(key: .lastModified, direction: .descending), title: "Last Modified", iconsByDirection: [:]),
            .init(sortOrder: .init(key: .dateAdded, direction: .descending), title: "Date Added", iconsByDirection: [:])
        ]

        var resultSortOption: SearchResultsSortOption?
        let sut = SearchResultsHeaderSortViewViewModel(
            selectedOption: sortOptions[0],
            displaySortOptionsViewModel: .init(title: sortTitle, sortOptions: sortOptions) { selectedSortOption in
                resultSortOption = selectedSortOption
            }
        )

        #expect(sut.showSortSheet == false)
        
        sut.changeSelection()

        #expect(resultSortOption?.sortOrder == nil)
        #expect(sut.showSortSheet)
    }
}
