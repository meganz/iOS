import MEGADomain
import MEGADomainMock
import MEGAL10n
import Testing
@testable import Transfer

@Suite("TransfersListViewModel More menu")
@MainActor
struct TransfersListViewModelMoreMenuTests {

    // MARK: - Active

    @Test func activeTab_withRows_offersSelectAndCancelAll() {
        let sut = makeSUT()
        sut.activePresence = 1
        sut.selectedTab = .active

        #expect(sut.menuActions == [.select, .cancelAll])
        #expect(sut.showsMoreMenu)
    }

    @Test func activeTab_withoutRows_hidesMoreMenu() {
        let sut = makeSUT()
        sut.selectedTab = .active

        #expect(sut.menuActions.isEmpty)
        #expect(!sut.showsMoreMenu)
    }

    // MARK: - Completed

    @Test func completedTab_withRows_offersSelectAndClearAll() {
        let sut = makeSUT()
        sut.completedPresence = 1
        sut.selectedTab = .completed

        #expect(sut.menuActions == [.select, .clearAll])
        #expect(sut.showsMoreMenu)
    }

    @Test func completedTab_withoutRows_hidesMoreMenu() {
        let sut = makeSUT()
        sut.selectedTab = .completed

        #expect(sut.menuActions.isEmpty)
        #expect(!sut.showsMoreMenu)
    }

    // MARK: - Failed

    @Test func failedTab_withRows_offersSelectRetryAllAndClearAll() {
        let sut = makeSUT()
        sut.failedPresence = 1
        sut.selectedTab = .failed

        #expect(sut.menuActions == [.select, .retryAll, .clearAll])
        #expect(sut.showsMoreMenu)
    }

    @Test func failedTab_withoutRows_hidesMoreMenu() {
        let sut = makeSUT()
        sut.selectedTab = .failed

        #expect(sut.menuActions.isEmpty)
        #expect(!sut.showsMoreMenu)
    }

    // MARK: - Menu reads only the selected tab

    @Test func menu_readsOnlyTheSelectedTabState() {
        let sut = makeSUT()
        sut.completedPresence = 1
        sut.failedPresence = 1

        // Active is empty even though other tabs have rows.
        sut.selectedTab = .active
        #expect(sut.menuActions.isEmpty)

        sut.selectedTab = .completed
        #expect(sut.menuActions == [.select, .clearAll])

        sut.selectedTab = .failed
        #expect(sut.menuActions == [.select, .retryAll, .clearAll])
    }

    // MARK: - Cancel-all confirmation

    @Test func requestCancelAll_presentsDialog() {
        let sut = makeSUT(hasActiveTransfers: true)

        sut.requestCancelAllConfirmation()

        #expect(sut.isPresentingCancelAllConfirmation)
    }

    @Test func confirmCancelAll_cancelsTransfers() {
        let listener = MockTransfersListenerUseCase()
        let sut = makeSUT(hasActiveTransfers: true, listener: listener)
        sut.requestCancelAllConfirmation()

        sut.confirmCancelAll()

        #expect(listener.cancelTransfersCalledTimes == 1)
    }

    @Test func dismissingDialog_runsNoAction() {
        let listener = MockTransfersListenerUseCase()
        let sut = makeSUT(hasActiveTransfers: true, listener: listener)
        sut.requestCancelAllConfirmation()

        // Tapping Dismiss flips the binding without confirming.
        sut.isPresentingCancelAllConfirmation = false

        #expect(listener.cancelTransfersCalledTimes == 0)
    }

    // MARK: - Clear-all (no confirmation)

    @Test func clearAll_onCompleted_clearsCompletedAndEmptiesTab() {
        let clear = MockClearTransfersUseCase()
        let sut = makeSUT(hasCompletedTransfers: true, clearTransfersUseCase: clear)
        sut.selectedTab = .completed

        sut.clearAllTransfers()

        #expect(clear.clearCompletedTransfersCalledTimes == 1)
        #expect(clear.clearFailedTransfersCalledTimes == 0)
        #expect(sut.hasCompletedTransfers == false)
    }

    @Test func clearAll_onFailed_clearsFailedAndEmptiesTab() {
        let clear = MockClearTransfersUseCase()
        let sut = makeSUT(hasFailedTransfers: true, clearTransfersUseCase: clear)
        sut.selectedTab = .failed

        sut.clearAllTransfers()

        #expect(clear.clearFailedTransfersCalledTimes == 1)
        #expect(clear.clearCompletedTransfersCalledTimes == 0)
        #expect(sut.hasFailedTransfers == false)
    }

    @Test func clearAll_onActive_doesNothing() {
        let clear = MockClearTransfersUseCase()
        let sut = makeSUT(hasActiveTransfers: true, clearTransfersUseCase: clear)
        sut.selectedTab = .active

        sut.clearAllTransfers()

        #expect(clear.clearCompletedTransfersCalledTimes == 0)
        #expect(clear.clearFailedTransfersCalledTimes == 0)
    }
}

@Suite("TransfersListViewModel presence observation")
@MainActor
struct TransfersListViewModelPresenceTests {

    @Test func freshlyConstructed_hasNoPresence() {
        let sut = makeSUT()

        #expect(!sut.hasActiveTransfers)
        #expect(!sut.hasCompletedTransfers)
        #expect(!sut.hasFailedTransfers)
    }

    @Test func activePresence_positive_marksActivePresent() {
        let sut = makeSUT()

        sut.activePresence = 3

        #expect(sut.hasActiveTransfers)
    }

    @Test func activePresence_droppingToZero_clearsActiveAndReseedsFromInventory() {
        let sut = makeSUT(completedTransfers: [
            .init(type: .download, tag: 1, state: .complete),
            .init(type: .upload, tag: 2, state: .failed)
        ])

        sut.activePresence = 2
        sut.activePresence = 0

        #expect(!sut.hasActiveTransfers)
        // Reaching zero re-seeds Completed/Failed so the tab bar survives a transfer
        // finishing in the Active tab (the other tabs aren't mounted to observe it).
        #expect(sut.hasCompletedTransfers)
        #expect(sut.hasFailedTransfers)
    }

    @Test func completedPresence_positive_marksCompletedPresent() {
        let sut = makeSUT()

        sut.completedPresence = 5

        #expect(sut.hasCompletedTransfers)
    }

    @Test func completedPresence_droppingToZero_keepsCompletedPresent() {
        let sut = makeSUT()

        sut.completedPresence = 5
        sut.completedPresence = 0

        // Upgrade-only: clearing completed transfers isn't supported, so a stale 0
        // (emitted while the tab mounts) must not hide the tab bar.
        #expect(sut.hasCompletedTransfers)
    }

    @Test func failedPresence_positive_marksFailedPresent() {
        let sut = makeSUT()

        sut.failedPresence = 1

        #expect(sut.hasFailedTransfers)
    }

    @Test func failedPresence_droppingToZero_keepsFailedPresent() {
        let sut = makeSUT()

        sut.failedPresence = 1
        sut.failedPresence = 0

        #expect(sut.hasFailedTransfers)
    }
}

@Suite("TransfersListViewModel inventory seeding")
@MainActor
struct TransfersListViewModelSeedingTests {

    @Test func seedCompletedPresence_withVisibleCompleted_setsTrue() {
        let sut = makeSUT(completedTransfers: [.init(type: .download, tag: 1, state: .complete)])

        sut.seedCompletedPresence()

        #expect(sut.hasCompletedTransfers)
    }

    @Test func seedCompletedPresence_withoutVisibleCompleted_setsFalse() {
        // A failed transfer isn't visible on the Completed tab.
        let sut = makeSUT(completedTransfers: [.init(type: .download, tag: 1, state: .failed)])

        sut.seedCompletedPresence()

        #expect(!sut.hasCompletedTransfers)
    }

    @Test func seedFailedPresence_withVisibleFailedOrCancelled_setsTrue() {
        let sut = makeSUT(completedTransfers: [.init(type: .upload, tag: 1, state: .cancelled)])

        sut.seedFailedPresence()

        #expect(sut.hasFailedTransfers)
    }

    @Test func seedFailedPresence_withoutVisibleFailed_setsFalse() {
        // A completed transfer isn't visible on the Failed tab.
        let sut = makeSUT(completedTransfers: [.init(type: .download, tag: 1, state: .complete)])

        sut.seedFailedPresence()

        #expect(!sut.hasFailedTransfers)
    }
}

@Suite("TransfersListViewModel pause all")
@MainActor
struct TransfersListViewModelPauseTests {

    @Test func isAllPaused_reflectsListenerStateOnInit() {
        #expect(makeSUT(listener: MockTransfersListenerUseCase(paused: true)).isAllPaused)
        #expect(!makeSUT(listener: MockTransfersListenerUseCase(paused: false)).isAllPaused)
    }

    @Test func togglePauseAll_whenNotPaused_pausesAndFlipsFlag() {
        let listener = MockTransfersListenerUseCase(paused: false)
        let sut = makeSUT(listener: listener)

        sut.togglePauseAll()

        #expect(listener.pauseTransfersCalledTimes == 1)
        #expect(listener.resumeTransfersCalledTimes == 0)
        #expect(sut.isAllPaused)
    }

    @Test func togglePauseAll_whenPaused_resumesAndFlipsFlag() {
        let listener = MockTransfersListenerUseCase(paused: true)
        let sut = makeSUT(listener: listener)

        sut.togglePauseAll()

        #expect(listener.resumeTransfersCalledTimes == 1)
        #expect(listener.pauseTransfersCalledTimes == 0)
        #expect(!sut.isAllPaused)
    }
}

@Suite("TransfersListViewModel derived state")
@MainActor
struct TransfersListViewModelDerivedStateTests {

    @Test func hasAnyTransfers_isFalseWhenNoTabHasRows() {
        #expect(!makeSUT().hasAnyTransfers)
    }

    @Test func hasAnyTransfers_isTrueWhenActiveHasRows() {
        let sut = makeSUT()
        sut.activePresence = 1
        #expect(sut.hasAnyTransfers)
    }

    @Test func hasAnyTransfers_isTrueWhenCompletedHasRows() {
        let sut = makeSUT()
        sut.completedPresence = 1
        #expect(sut.hasAnyTransfers)
    }

    @Test func hasAnyTransfers_isTrueWhenFailedHasRows() {
        let sut = makeSUT()
        sut.failedPresence = 1
        #expect(sut.hasAnyTransfers)
    }

    @Test func isCurrentTabEmpty_tracksTheSelectedTab() {
        let sut = makeSUT()
        sut.activePresence = 1

        sut.selectedTab = .active
        #expect(!sut.isCurrentTabEmpty)

        sut.selectedTab = .completed
        #expect(sut.isCurrentTabEmpty)
    }
}

// MARK: - Helpers

@MainActor
private func makeSUT(
    completedTransfers: [TransferEntity] = [],
    hasActiveTransfers: Bool = false,
    hasCompletedTransfers: Bool = false,
    hasFailedTransfers: Bool = false,
    listener: MockTransfersListenerUseCase = MockTransfersListenerUseCase(),
    clearTransfersUseCase: MockClearTransfersUseCase = MockClearTransfersUseCase(),
    filteringUserTransfers: Bool = true
) -> TransfersListViewModel {
    let sut = TransfersListViewModel(
        dependency: makeDependency(
            completedTransfers: completedTransfers,
            filteringUserTransfers: filteringUserTransfers,
            clearTransfersUseCase: clearTransfersUseCase
        ),
        transfersListenerUseCase: listener
    )
    // Seed tab-presence through the same `*Presence` channel production uses, so a
    // test can spin up a VM in a known tab-bar state in one call.
    if hasActiveTransfers { sut.activePresence = 1 }
    if hasCompletedTransfers { sut.completedPresence = 1 }
    if hasFailedTransfers { sut.failedPresence = 1 }
    return sut
}

@MainActor
private func makeDependency(
    completedTransfers: [TransferEntity] = [],
    filteringUserTransfers: Bool = true,
    clearTransfersUseCase: MockClearTransfersUseCase = MockClearTransfersUseCase()
) -> TransferTabDependency {
    TransferTabDependency(
        inventoryUseCase: MockTransferInventoryUseCase(completedTransfers: completedTransfers),
        counterUseCase: MockTransferCounterUseCase(),
        registry: TransferRegistry(),
        locationResolver: StubTransferLocationResolver(),
        filteringUserTransfers: filteringUserTransfers,
        clearTransfersUseCase: clearTransfersUseCase
    )
}

private struct StubTransferLocationResolver: TransferLocationResolving {
    func location(for entity: TransferEntity) async -> String? { nil }
}
