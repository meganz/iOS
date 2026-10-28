@testable import ContinueWhereYouLeftOff
import ContinueWhereYouLeftOffMock
import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import MEGAUIComponent
import Search
import Testing

@Suite("LeftOffItemsViewModel", .timeLimit(.minutes(1)))
@MainActor
struct LeftOffItemsViewModelTests {
    // MARK: - Analytics

    @Test("the screen appearing sends the screen event")
    func onAppearTracksScreenEvent() {
        let (sut, tracker) = makeSUT()

        sut.onAppear()

        #expect(trackedEventTypes(tracker) == [ObjectIdentifier(ContinueWhereLeftOffScreenEvent.self)])
    }

    @Test("selecting an item sends the list item event and opens the node")
    func didSelectTracksEventAndOpensNode() {
        let opened = OpenedHandles()
        let (sut, tracker) = makeSUT(openNode: { opened.append($0) })

        sut.didSelect(selection(for: 7))

        #expect(trackedEventTypes(tracker) == [ObjectIdentifier(ContinueWhereLeftOffListItemPressedEvent.self)])
        #expect(opened.handles == [7])
    }

    @Test("asking to clear the history sends the menu item event")
    func requestClearAllItemsTracksEvent() {
        let (sut, tracker) = makeSUT()

        sut.requestClearAllItems()

        #expect(trackedEventTypes(tracker) == [ObjectIdentifier(ContinueWhereLeftOffClearHistoryMenuItemEvent.self)])
        #expect(sut.isPresentingClearAllConfirmation)
    }

    @Test("confirming the clear sends the dialog confirmed event")
    func clearAllItemsTracksEvent() async {
        let useCase = MockLeftOffItemsUseCase()
        let (sut, tracker) = makeSUT(useCase: useCase)

        let isCleared = await sut.clearAllItems()

        #expect(trackedEventTypes(tracker) == [ObjectIdentifier(ContinueWhereLeftOffClearHistoryDialogConfirmedEvent.self)])
        #expect(isCleared)
        #expect(useCase.clearHistoryCallCount == 1)
    }

    @Test("asking to clear the selected items sends the toolbar event")
    func requestClearSelectedItemsTracksEvent() {
        let (sut, tracker) = makeSUT()
        sut.selectionDidChange([7])

        sut.requestClearSelectedItems()

        #expect(trackedEventTypes(tracker) == [ObjectIdentifier(ContinueWhereLeftOffRemoveSelectedMenuToolbarEvent.self)])
        #expect(sut.isPresentingClearSelectedConfirmation)
    }

    @Test("asking to clear with no selection sends nothing")
    func requestClearSelectedItemsWithoutSelectionTracksNothing() {
        let (sut, tracker) = makeSUT()

        sut.requestClearSelectedItems()

        #expect(tracker.trackedEventIdentifiers.isEmpty)
        #expect(!sut.isPresentingClearSelectedConfirmation)
    }

    @Test("confirming the clear of the selected items sends the confirm event")
    func clearSelectedItemsTracksEvent() async {
        let (sut, tracker) = makeSUT()
        sut.selectionDidChange([7])

        await sut.clearSelectedItems()

        #expect(trackedEventTypes(tracker) == [ObjectIdentifier(ContinueWhereLeftOffRemoveSelectedConfirmButtonPressedEvent.self)])
    }

    @Test("each sort choice sends its own event")
    func sortOrderChangesTrackEvents() async {
        let (sut, tracker) = makeSUT()
        let container = sut.searchResultsContainerViewModel

        container.changeSortOrder(.init(key: .name, direction: .ascending))
        await waitUntil { tracker.trackedEventIdentifiers.count == 1 }
        container.changeSortOrder(.init(key: .name, direction: .descending))
        await waitUntil { tracker.trackedEventIdentifiers.count == 2 }
        container.changeSortOrder(.init(key: .dateAdded, direction: .ascending))
        await waitUntil { tracker.trackedEventIdentifiers.count == 3 }
        container.changeSortOrder(.init(key: .dateAdded, direction: .descending))
        await waitUntil { tracker.trackedEventIdentifiers.count == 4 }

        #expect(trackedEventTypes(tracker) == [
            ObjectIdentifier(ContinueWhereLeftOffSortByNameAscendingSelectedEvent.self),
            ObjectIdentifier(ContinueWhereLeftOffSortByNameDescendingSelectedEvent.self),
            ObjectIdentifier(ContinueWhereLeftOffSortByDateOldestSelectedEvent.self),
            ObjectIdentifier(ContinueWhereLeftOffSortByDateNewestSelectedEvent.self)
        ])
    }

    @Test("a sort key without an event sends nothing")
    func otherSortKeyTracksNothing() async {
        let (sut, tracker) = makeSUT()
        let container = sut.searchResultsContainerViewModel

        container.changeSortOrder(.init(key: .size, direction: .descending))
        container.changeSortOrder(.init(key: .name, direction: .ascending))
        await waitUntil { tracker.trackedEventIdentifiers.isNotEmpty }

        #expect(trackedEventTypes(tracker) == [ObjectIdentifier(ContinueWhereLeftOffSortByNameAscendingSelectedEvent.self)])
    }

    @Test("switching the view mode sends the grid and list events")
    func viewModeChangesTrackEvents() {
        let (sut, tracker) = makeSUT()
        let bridge = sut.searchResultsContainerViewModel.bridge

        bridge.viewModeChanged(.grid)
        bridge.viewModeChanged(.list)

        #expect(trackedEventTypes(tracker) == [
            ObjectIdentifier(ContinueWhereLeftOffGridViewSelectedEvent.self),
            ObjectIdentifier(ContinueWhereLeftOffListViewSelectedEvent.self)
        ])
    }

    @Test("choosing the current view mode again sends nothing")
    func sameViewModeTracksNothing() {
        let (sut, tracker) = makeSUT()

        sut.searchResultsContainerViewModel.bridge.viewModeChanged(.list)

        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

    // MARK: - Helpers

    @MainActor
    private final class OpenedHandles {
        private(set) var handles: [HandleEntity] = []

        func append(_ handle: HandleEntity) {
            handles.append(handle)
        }
    }

    private func makeSUT(
        useCase: MockLeftOffItemsUseCase = MockLeftOffItemsUseCase(),
        openNode: @escaping @MainActor (HandleEntity) -> Void = { _ in }
    ) -> (sut: LeftOffItemsViewModel, tracker: MockTracker) {
        let tracker = MockTracker()
        let sut = LeftOffItemsViewModel(
            leftOffItemsUseCase: useCase,
            thumbnailUseCase: MockThumbnailUseCase(),
            openNode: openNode,
            tracker: tracker
        )
        return (sut, tracker)
    }

    private func selection(for handle: HandleEntity) -> SearchResultSelection {
        let node = NodeEntity(name: "file\(handle).pdf", handle: handle)
        let item = ResolvedLeftOffItemEntity(
            item: LeftOffItemEntity(handle: handle, name: node.name, lastAccessed: .now),
            node: node
        )
        let result = LeftOffItemSearchResultMapper(thumbnailUseCase: MockThumbnailUseCase()).map(item: item)
        return SearchResultSelection(result: result, siblingsProvider: { [] })
    }

    private func trackedEventTypes(_ tracker: MockTracker) -> [ObjectIdentifier] {
        tracker.trackedEventIdentifiers.map { ObjectIdentifier(type(of: $0)) }
    }

    private func waitUntil(_ condition: () -> Bool) async {
        while !condition() {
            try? await Task.sleep(for: .milliseconds(2))
        }
    }
}
