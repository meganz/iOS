@testable import Search
import Testing

@MainActor
struct SearchResultsHeaderSortViewViewModelTests {
    @Test func testSelectionChanged_whenChanged_shouldDismissSheetAndChangeSelection() {
        let sortTitle = "Sort By"
        let sortOptions: [SearchResultsSortOption] = [
            .init(sortOrder: .init(key: .name), title: "Name", iconsByDirection: [:]),
            .init(sortOrder: .init(key: .name, direction: .descending), title: "Name", iconsByDirection: [:]),
            .init(sortOrder: .init(key: .dateAdded), title: "Name", iconsByDirection: [:]),

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
}
