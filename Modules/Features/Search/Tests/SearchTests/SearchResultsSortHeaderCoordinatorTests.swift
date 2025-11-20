import Foundation
import MEGASwift
@testable import Search
import Testing

@MainActor
struct SearchResultsSortHeaderCoordinatorTests {

    @Test func testHeaderViewModel_basedOnSelectedSortOrder_shouldMatchResults() {
        let sut = makeSUT(currentSortOrderProvider: { .init(key: .name, direction: .descending) })
        #expect(sut.headerViewModel.selectedOption.sortOrder == .init(key: .name, direction: .descending))
    }

    @Test func testDisplaySortOptionsViewModel_basedOnSelectedSortOrder_shouldExcludeItInMatchResults() {
        let sut = makeSUT(currentSortOrderProvider: { .init(key: .name, direction: .ascending) })
        #expect(
            sut.displaySortOptionsViewModel.sortOptions.map(\.sortOrder) == [
                .init(key: .name, direction: .descending),
                .init(key: .favourite),
                .init(key: .dateAdded)
            ]
        )
    }

    @Test func testDisplaySortOptionsViewModelTapHandler_whenInvoked_shouldMatchResults() async throws {
        let order = Box<SortOrderEntity>(.init(key: .name))
        let currentSortOrderProvider = { order.value }
        let sut = makeSUT(currentSortOrderProvider: currentSortOrderProvider)
        #expect(sut.headerViewModel.selectedOption.sortOrder == .init(key: .name))
        order.value = .init(key: .dateAdded)
        sut.displaySortOptionsViewModel.tapHandler?(
            .init(sortOrder: .init(key: .dateAdded), title: "Date added", iconsByDirection: [:])
        )
        try await waitUntil(
            await MainActor.run {
                sut.displaySortOptionsViewModel.sortOptions.map(\.sortOrder).contains(.init(key: .dateAdded))
            }
        )
        #expect(sut.headerViewModel.selectedOption.sortOrder == .init(key: .dateAdded))
        #expect(
            sut.displaySortOptionsViewModel.sortOptions.map(\.sortOrder) == [
                .init(key: .name),
                .init(key: .favourite)
            ]
        )
    }

    @Test func testUpdateSortUI_whenInvoked_shouldMatchResults() {
        let order = Box<SortOrderEntity>(.init(key: .name, direction: .descending))
        let currentSortOrderProvider = { order.value }
        let sut = makeSUT(currentSortOrderProvider: currentSortOrderProvider)
        #expect(sut.headerViewModel.selectedOption.sortOrder == .init(key: .name, direction: .descending))
        order.value = .init(key: .favourite)
        sut.updateSortUI()
        #expect(sut.headerViewModel.selectedOption.sortOrder == .init(key: .favourite))
        #expect(
            sut.displaySortOptionsViewModel.sortOptions.map(\.sortOrder) == [
                .init(key: .name),
                .init(key: .dateAdded)
            ]
        )
    }

    private func waitUntil(
        timeout: TimeInterval = 2.0,
        _ condition: @Sendable @autoclosure @escaping () async -> Bool
    ) async throws {
        try await withTimeout(seconds: timeout) {
            while await condition() {
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
        }
    }

    func makeSUT(
        sortOptions: [SearchResultsSortOption] = [
            .init(sortOrder: .init(key: .name), title: "Name", iconsByDirection: [:]),
            .init(sortOrder: .init(key: .name, direction: .descending), title: "Name", iconsByDirection: [:]),
            .init(sortOrder: .init(key: .favourite), title: "Favourite", iconsByDirection: [:]),
            .init(sortOrder: .init(key: .dateAdded), title: "Date added", iconsByDirection: [:])
        ],
        currentSortOrderProvider: @escaping () -> SortOrderEntity = { .init(key: .name) }
    ) -> SearchResultsSortHeaderCoordinator {
        .init(
            sortOptionsViewModel: .init(
                title: "Sort By",
                sortOptions: sortOptions
            ),
            currentSortOrderProvider: currentSortOrderProvider,
            sortOptionSelectionHandler: { _ in }
        )
    }
}

private final class Box<T> {
    var value: T
    init(_ value: T) { self.value = value }
}
