import Favourites
import MEGAAppPresentation
import MEGADomain
import MEGADomainMock
@testable import MEGAUIComponent
@testable import Search
import SearchMock
import SwiftUI
import Testing
import UIKit

@MainActor
struct FavouritesViewModelTests {

    // MARK: - Sort options

    @Test
    func sortHeaderConfigContainsAllExpectedKeys() {
        let sut = makeSUT()
        let keys = sut.searchResultsContainerViewModel.sortHeaderConfig.options.map(\.id)

        #expect(keys.contains(.name))
        #expect(keys.contains(.favourite))
        #expect(keys.contains(.label))
        #expect(keys.contains(.dateAdded))
        #expect(keys.contains(.lastModified))
        #expect(keys.contains(.size))
        #expect(keys.count == 6)
    }

    // MARK: - Initial sort order

    @Test
    func initialSortOrderIsReadFromPreferenceUseCase() {
        let useCase = MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc)
        let sut = makeSUT(sortOrderPreferenceUseCase: useCase)

        let containerVM = sut.searchResultsContainerViewModel
        let sortOrder = containerVM.bridge.sortingOrder()

        #expect(sortOrder == .init(key: .name))
        #expect(useCase.messages.contains(.sortOrder(key: .homeFavourites)))
    }

    // MARK: - Save sort order

    @Test
    func updatingSortOrderCallsSaveOnPreferenceUseCase() async {
        let useCase = MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc)
        let sut = makeSUT(sortOrderPreferenceUseCase: useCase)

        let newSortOrder = MEGAUIComponent.SortOrder(key: .lastModified)
        sut.searchResultsContainerViewModel.bridge.updateSortOrder(newSortOrder)

        #expect(useCase.messages.contains(.save(sortOrder: .modificationAsc, for: .homeFavourites)))
    }

    // MARK: - External sort order monitoring

    @Test
    func initStartsMonitoringSortOrderForHomeFavourites() {
        let useCase = MockSortOrderPreferenceUseCase()
        _ = makeSUT(sortOrderPreferenceUseCase: useCase)

        #expect(useCase.messages.contains(.monitorSortOrder(key: .homeFavourites)))
    }

    // MARK: - Edit mode

    @Test
    func initialEditModeIsInactive() {
        let sut = makeSUT()

        #expect(sut.editMode == .inactive)
    }

    @Test
    func exitEditModeSetsEditModeToInactive() {
        let sut = makeSUT()
        sut.editMode = .active

        sut.exitEditMode()

        #expect(sut.editMode == .inactive)
    }

    @Test
    func editingChangedTrueViaBridgeSetsEditModeToActive() async throws {
        let sut = makeSUT()

        sut.searchResultsContainerViewModel.bridge.editingChanged(true)

        try await waitForCondition { sut.editMode == .active }
        #expect(sut.editMode == .active)
    }

    @Test
    func editingChangedFalseViaBridgeSetsEditModeToInactive() async throws {
        let sut = makeSUT()
        sut.editMode = .active

        sut.searchResultsContainerViewModel.bridge.editingChanged(false)

        try await waitForCondition { sut.editMode == .inactive }
        #expect(sut.editMode == .inactive)
    }

    @Test
    func changingEditModeToInactiveClearsSelection() async throws {
        let sut = makeSUT()
        sut.editMode = .active
        sut.selectedNodeHandles = [1, 2, 3]

        sut.editMode = .inactive

        try await waitForCondition { sut.selectedNodeHandles.isEmpty }
        #expect(sut.selectedNodeHandles.isEmpty)
    }

    // MARK: - Selection

    @Test
    func initialSelectedNodeHandlesIsEmpty() {
        let sut = makeSUT()

        #expect(sut.selectedNodeHandles.isEmpty)
    }

    @Test
    func toggleSelectAllDelegatesToSearchResultsContainer() {
        let sut = makeSUT()
        sut.editMode = .active

        sut.toggleSelectAll()

        // This test verifies the method is called without error
        // Actual selection behavior is tested in SearchResultsContainerViewModel tests
    }

    @Test
    func selectionChangedViaBridgeUpdatesSelectedNodeHandles() async throws {
        let sut = makeSUT()

        sut.searchResultsContainerViewModel.bridge.selectionChanged([10, 20, 30])

        try await waitForCondition { !sut.selectedNodeHandles.isEmpty }
        #expect(sut.selectedNodeHandles == [10, 20, 30])
    }

    // MARK: - Bottom bar state

    @Test
    func bottomBarDisabledWhenEditModeIsInactive() {
        let sut = makeSUT()
        sut.editMode = .inactive
        sut.selectedNodeHandles = [1, 2, 3]

        #expect(sut.bottomBarDisabled == true)
    }

    @Test
    func bottomBarDisabledWhenNoNodesSelected() async throws {
        let sut = makeSUT()
        sut.editMode = .active

        sut.selectedNodeHandles = []

        try await waitForCondition { sut.bottomBarDisabled == true }
        #expect(sut.bottomBarDisabled == true)
    }

    @Test
    func bottomBarEnabledWhenInEditModeWithSelection() async throws {
        let sut = makeSUT()
        sut.editMode = .active

        sut.selectedNodeHandles = [1, 2, 3]

        try await waitForCondition { sut.bottomBarDisabled == false }
        #expect(sut.bottomBarDisabled == false)
    }

    // MARK: - Bottom bar actions

    @Test
    func downloadActionCreatesDownloadNodesAction() async throws {
        let sut = makeSUT()
        sut.selectedNodeHandles = [1, 2, 3]

        sut.bottomBarAction = .download

        try await waitForCondition {
            if case .download = sut.nodesAction { return true }
            return false
        }
        guard case .download(let handles) = sut.nodesAction else {
            #expect(Bool(false), "Expected download action")
            return
        }
        #expect(handles == [1, 2, 3])
    }

    @Test
    func removeFavouriteActionCreatesToggleFavouritesNodesAction() async throws {
        let sut = makeSUT()
        sut.selectedNodeHandles = [4, 5]

        sut.bottomBarAction = .removeFavourite

        try await waitForCondition {
            if case .toggleFavourites = sut.nodesAction { return true }
            return false
        }
        guard case .toggleFavourites(let handles) = sut.nodesAction else {
            #expect(Bool(false), "Expected toggleFavourites action")
            return
        }
        #expect(handles == [4, 5])
    }

    @Test
    func shareLinkActionCreatesShareLinkNodesAction() async throws {
        let sut = makeSUT()
        sut.selectedNodeHandles = [6, 7, 8]

        sut.bottomBarAction = .shareLink

        try await waitForCondition {
            if case .shareLink = sut.nodesAction { return true }
            return false
        }
        guard case .shareLink(let handles) = sut.nodesAction else {
            #expect(Bool(false), "Expected shareLink action")
            return
        }
        #expect(handles == [6, 7, 8])
    }

    @Test
    func moveToRubbishBinActionCreatesMoveToRubbishBinNodesAction() async throws {
        let sut = makeSUT()
        sut.selectedNodeHandles = [9]

        sut.bottomBarAction = .moveToRubbishBin

        try await waitForCondition {
            if case .moveToRubbishBin = sut.nodesAction { return true }
            return false
        }
        guard case .moveToRubbishBin(let handles) = sut.nodesAction else {
            #expect(Bool(false), "Expected moveToRubbishBin action")
            return
        }
        #expect(handles == [9])
    }

    @Test
    func moreActionCreatesMoreNodesAction() async throws {
        let sut = makeSUT()
        sut.selectedNodeHandles = [10, 11]

        sut.bottomBarAction = .more

        try await waitForCondition {
            if case .more = sut.nodesAction { return true }
            return false
        }
        guard case .more(let handles) = sut.nodesAction else {
            #expect(Bool(false), "Expected more action")
            return
        }
        #expect(handles == [10, 11])
    }

    // MARK: - Nodes action auto-exits edit mode

    @Test(arguments: [BottomBarAction.download, .removeFavourite, .shareLink, .moveToRubbishBin])
    func nonMoreBottomBarActionsExitEditMode(_ action: BottomBarAction) async throws {
        let sut = makeSUT()
        sut.editMode = .active
        sut.selectedNodeHandles = [1, 2, 3]

        sut.bottomBarAction = action

        try await waitForCondition { sut.editMode == .inactive }
        #expect(sut.editMode == .inactive)
    }

    @Test
    func moreBottomBarActionDoesNotExitEditMode() async throws {
        let sut = makeSUT()
        sut.editMode = .active
        sut.selectedNodeHandles = [1, 2, 3]

        sut.bottomBarAction = .more

        // Wait for nodesAction to be set so we know the action was processed
        try await waitForCondition {
            if case .more = sut.nodesAction { return true }
            return false
        }
        // Edit mode stays active — it exits at the View layer via onNodeActionPerformed
        #expect(sut.editMode == .active)
    }

    // MARK: - Node action (context menu)

    @Test
    func contextActionSetsNodeActionWithCorrectHandle() async throws {
        let sut = makeSUT()
        let button = UIButton()
        let result = SearchResult.resultWith(id: 99)

        sut.searchResultsContainerViewModel.bridge.context(result, button)

        try await waitForCondition { sut.nodeAction != nil }
        #expect(sut.nodeAction?.handle == 99)
        #expect(sut.nodeAction?.sender === button)
    }

    // MARK: - View mode

    @Test
    func initialViewModeIsList() {
        let sut = makeSUT()

        #expect(sut.viewMode == .list)
    }

    @Test
    func viewModeChangedToGridViaBridgeUpdatesViewMode() async throws {
        let sut = makeSUT()

        sut.searchResultsContainerViewModel.bridge.viewModeChanged(.grid)

        try await waitForCondition { sut.viewMode == .grid }
        #expect(sut.viewMode == .grid)
    }

    @Test
    func viewModeChangedBackToListViaBridgeUpdatesViewMode() async throws {
        let sut = makeSUT()
        sut.searchResultsContainerViewModel.bridge.viewModeChanged(.grid)
        try await waitForCondition { sut.viewMode == .grid }

        sut.searchResultsContainerViewModel.bridge.viewModeChanged(.list)

        try await waitForCondition { sut.viewMode == .list }
        #expect(sut.viewMode == .list)
    }

    // MARK: - Search text

    @Test
    func initialSearchTextIsEmpty() {
        let sut = makeSUT()
        #expect(sut.searchText.isEmpty)
    }

    @Test
    func searchTextChangesCallQueryChangedOnBridge() async throws {
        let sut = makeSUT()
        var queriedTexts: [String] = []
        sut.searchResultsContainerViewModel.bridge.queryChanged = { queriedTexts.append($0) }

        sut.searchText = "test query"

        try await waitForCondition { queriedTexts.contains("test query") }
        #expect(queriedTexts.contains("test query"))
    }

    @Test
    func emptySearchTextWithInactiveSearchCallsQueryCleaned() async throws {
        let sut = makeSUT()
        sut.searchText = "initial"

        var queryCleanedCalled = false
        sut.searchResultsContainerViewModel.bridge.queryCleaned = { queryCleanedCalled = true }

        sut.searchText = ""

        try await waitForCondition { queryCleanedCalled }
        #expect(queryCleanedCalled)
    }

    @Test
    func emptySearchTextWithActiveSearchCallsQueryChangedNotCleaned() async throws {
        let sut = makeSUT()
        sut.searchBecameActive = true
        sut.searchText = "something"

        var queryCleanedCalled = false
        var queriedTexts: [String] = []
        sut.searchResultsContainerViewModel.bridge.queryCleaned = { queryCleanedCalled = true }
        sut.searchResultsContainerViewModel.bridge.queryChanged = { queriedTexts.append($0) }

        sut.searchText = ""

        try await waitForCondition { queriedTexts.contains("") }
        #expect(!queryCleanedCalled)
        #expect(queriedTexts.contains(""))
    }

    // MARK: - Search active state

    @Test
    func initialSearchBecameActiveIsFalse() {
        let sut = makeSUT()
        #expect(sut.searchBecameActive == false)
    }

    @Test
    func searchBecameActiveChangesArePropagated() {
        let sut = makeSUT()
        sut.searchBecameActive = true
        #expect(sut.searchBecameActive == true)
        sut.searchBecameActive = false
        #expect(sut.searchBecameActive == false)
    }

    // MARK: - Node selection

    @Test
    func tappingNodeSetsSelectionWithCorrectHandleAndSiblings() async throws {
        let sut = makeSUT()

        let selection = SearchResultSelection.resultSelectionWith(id: 42, title: "test", siblings: [1, 2, 3])
        sut.searchResultsContainerViewModel.bridge.selection(selection)

        try await waitForCondition { sut.selection != nil }
        #expect(sut.selection?.handle == 42)
        #expect(sut.selection?.siblings == [1, 2, 3])
    }

    // MARK: - Helpers

    private func makeSUT(
        sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase = MockSortOrderPreferenceUseCase()
    ) -> FavouritesViewModel {
        FavouritesViewModel(
            dependency: .init(
                resultsProvider: MockSearchResultsProviding(),
                sortOrderPreferenceUseCase: sortOrderPreferenceUseCase
            )
        )
    }

    /// Wait for a condition to be true with timeout
    private func waitForCondition(
        timeout: Duration = .seconds(2),
        pollingInterval: Duration = .milliseconds(10),
        condition: @escaping () -> Bool
    ) async throws {
        let startTime = ContinuousClock.now
        while !condition() {
            if ContinuousClock.now - startTime > timeout {
                throw TimeoutError()
            }
            try await Task.sleep(for: pollingInterval)
        }
    }

    private struct TimeoutError: Error {}
}
