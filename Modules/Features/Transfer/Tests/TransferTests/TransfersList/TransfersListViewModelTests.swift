import AsyncAlgorithms
import Foundation
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing
@testable import Transfer

@Suite("TransfersListViewModel More menu")
@MainActor
struct TransfersListViewModelMoreMenuTests {

    // MARK: - Active

    @Test func activeTab_withRows_offersSelectAndCancelAll() async {
        let sut = makeSUT(hasActiveTransfers: true)
        await sut.observeTabPresence()
        sut.selectedTab = .active

        #expect(sut.menuActions == [.select, .cancelAll])
        #expect(sut.showsMoreMenu)
    }

    @Test func activeTab_withoutRows_hidesMoreMenu() async {
        let sut = makeSUT()
        await sut.observeTabPresence()
        sut.selectedTab = .active

        #expect(sut.menuActions.isEmpty)
        #expect(!sut.showsMoreMenu)
    }

    // MARK: - Completed

    @Test func completedTab_withRows_offersSelectAndClearAll() async {
        let sut = makeSUT(hasCompletedTransfers: true)
        await sut.observeTabPresence()
        sut.selectedTab = .completed

        #expect(sut.menuActions == [.select, .clearAll])
        #expect(sut.showsMoreMenu)
    }

    @Test func completedTab_withoutRows_hidesMoreMenu() async {
        let sut = makeSUT()
        await sut.observeTabPresence()
        sut.selectedTab = .completed

        #expect(sut.menuActions.isEmpty)
        #expect(!sut.showsMoreMenu)
    }

    // MARK: - Failed

    @Test func failedTab_withRows_offersSelectRetryAllAndClearAll() async {
        let sut = makeSUT(hasFailedTransfers: true)
        await sut.observeTabPresence()
        sut.selectedTab = .failed

        #expect(sut.menuActions == [.select, .retryAll, .clearAll])
        #expect(sut.showsMoreMenu)
    }

    @Test func failedTab_withoutRows_hidesMoreMenu() async {
        let sut = makeSUT()
        await sut.observeTabPresence()
        sut.selectedTab = .failed

        #expect(sut.menuActions.isEmpty)
        #expect(!sut.showsMoreMenu)
    }

    // MARK: - Menu reads only the selected tab

    @Test func menu_readsOnlyTheSelectedTabState() async {
        let sut = makeSUT(hasCompletedTransfers: true, hasFailedTransfers: true)
        await sut.observeTabPresence()

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
        let sut = makeSUT()

        sut.requestCancelAllConfirmation()

        #expect(sut.isPresentingCancelAllConfirmation)
    }

    @Test func confirmCancelAll_cancelsTransfers() {
        let useCase = MockTransferListUseCase()
        let sut = makeSUT(useCase: useCase)
        sut.requestCancelAllConfirmation()

        sut.confirmCancelAll()

        #expect(useCase.cancelTransfersCalledTimes == 1)
    }

    @Test func dismissingDialog_runsNoAction() {
        let useCase = MockTransferListUseCase()
        let sut = makeSUT(useCase: useCase)
        sut.requestCancelAllConfirmation()

        // Tapping Dismiss flips the binding without confirming.
        sut.isPresentingCancelAllConfirmation = false

        #expect(useCase.cancelTransfersCalledTimes == 0)
    }

    // MARK: - Clear-all (no confirmation)

    @Test func clearAll_onCompleted_clearsCompleted() {
        let clear = MockClearTransfersUseCase()
        let sut = makeSUT(clearTransfersUseCase: clear)
        sut.selectedTab = .completed

        sut.clearAllTransfers()

        #expect(clear.clearCompletedTransfersCalledTimes == 1)
        #expect(clear.clearFailedTransfersCalledTimes == 0)
    }

    @Test func clearAll_onFailed_clearsFailed() {
        let clear = MockClearTransfersUseCase()
        let sut = makeSUT(clearTransfersUseCase: clear)
        sut.selectedTab = .failed

        sut.clearAllTransfers()

        #expect(clear.clearFailedTransfersCalledTimes == 1)
        #expect(clear.clearCompletedTransfersCalledTimes == 0)
    }

    @Test func clearAll_onActive_doesNothing() {
        let clear = MockClearTransfersUseCase()
        let sut = makeSUT(clearTransfersUseCase: clear)
        sut.selectedTab = .active

        sut.clearAllTransfers()

        #expect(clear.clearCompletedTransfersCalledTimes == 0)
        #expect(clear.clearFailedTransfersCalledTimes == 0)
    }
}

@Suite("TransfersListViewModel presence")
@MainActor
struct TransfersListViewModelPresenceTests {

    @Test func freshlyConstructed_hasNoPresence() {
        let sut = makeSUT(hasActiveTransfers: true, hasCompletedTransfers: true, hasFailedTransfers: true)

        // Presence stays empty until the observer runs.
        #expect(!sut.hasActiveTransfers)
        #expect(!sut.hasCompletedTransfers)
        #expect(!sut.hasFailedTransfers)
    }

    @Test func observeTabPresence_appliesEmittedPresence() async {
        let sut = makeSUT(hasActiveTransfers: true, hasCompletedTransfers: true)

        await sut.observeTabPresence()

        #expect(sut.hasActiveTransfers)
        #expect(sut.hasCompletedTransfers)
        #expect(!sut.hasFailedTransfers)
    }

    @Test func observeTabPresence_appliesLatestOfMultipleEmissions() async {
        let updates = [
            TransferTabPresence(hasActive: true, hasCompleted: false, hasFailed: false),
            TransferTabPresence(hasActive: false, hasCompleted: true, hasFailed: false)
        ].async.eraseToAnyAsyncSequence()
        let sut = makeSUT(presenceUpdates: updates)

        await sut.observeTabPresence()

        #expect(!sut.hasActiveTransfers)
        #expect(sut.hasCompletedTransfers)
    }
}

@Suite("TransfersListViewModel pause all")
@MainActor
struct TransfersListViewModelPauseTests {

    @Test func isAllPaused_reflectsUseCaseStateOnInit() {
        #expect(makeSUT(useCase: MockTransferListUseCase(paused: true)).isAllPaused)
        #expect(!makeSUT(useCase: MockTransferListUseCase(paused: false)).isAllPaused)
    }

    @Test func togglePauseAll_whenNotPaused_pausesAndFlipsFlag() {
        let useCase = MockTransferListUseCase(paused: false)
        let sut = makeSUT(useCase: useCase)

        sut.togglePauseAll()

        #expect(useCase.pauseTransfersCalledTimes == 1)
        #expect(useCase.resumeTransfersCalledTimes == 0)
        #expect(sut.isAllPaused)
    }

    @Test func togglePauseAll_whenPaused_resumesAndFlipsFlag() {
        let useCase = MockTransferListUseCase(paused: true)
        let sut = makeSUT(useCase: useCase)

        sut.togglePauseAll()

        #expect(useCase.resumeTransfersCalledTimes == 1)
        #expect(useCase.pauseTransfersCalledTimes == 0)
        #expect(!sut.isAllPaused)
    }
}

@Suite("TransfersListViewModel derived state")
@MainActor
struct TransfersListViewModelDerivedStateTests {

    @Test func hasAnyTransfers_isFalseWhenNoTabHasRows() async {
        let sut = makeSUT()
        await sut.observeTabPresence()
        #expect(!sut.hasAnyTransfers)
    }

    @Test func hasAnyTransfers_isTrueWhenActiveHasRows() async {
        let sut = makeSUT(hasActiveTransfers: true)
        await sut.observeTabPresence()
        #expect(sut.hasAnyTransfers)
    }

    @Test func hasAnyTransfers_isTrueWhenCompletedHasRows() async {
        let sut = makeSUT(hasCompletedTransfers: true)
        await sut.observeTabPresence()
        #expect(sut.hasAnyTransfers)
    }

    @Test func hasAnyTransfers_isTrueWhenFailedHasRows() async {
        let sut = makeSUT(hasFailedTransfers: true)
        await sut.observeTabPresence()
        #expect(sut.hasAnyTransfers)
    }

    @Test func isCurrentTabEmpty_tracksTheSelectedTab() async {
        let sut = makeSUT(hasActiveTransfers: true)
        await sut.observeTabPresence()

        sut.selectedTab = .active
        #expect(!sut.isCurrentTabEmpty)

        sut.selectedTab = .completed
        #expect(sut.isCurrentTabEmpty)
    }
}

// MARK: - Helpers

@MainActor
private func makeSUT(
    hasActiveTransfers: Bool = false,
    hasCompletedTransfers: Bool = false,
    hasFailedTransfers: Bool = false,
    useCase: MockTransferListUseCase = MockTransferListUseCase(),
    presenceUpdates: AnyAsyncSequence<TransferTabPresence>? = nil,
    clearTransfersUseCase: MockClearTransfersUseCase = MockClearTransfersUseCase()
) -> TransfersListViewModel {
    let seed = TransferTabPresence(
        hasActive: hasActiveTransfers,
        hasCompleted: hasCompletedTransfers,
        hasFailed: hasFailedTransfers
    )
    return TransfersListViewModel(
        dependency: makeDependency(clearTransfersUseCase: clearTransfersUseCase),
        transferListUseCase: useCase,
        monitorPresenceUseCase: MockMonitorTransferTabPresenceUseCase(
            presenceUpdates: presenceUpdates ?? [seed].async.eraseToAnyAsyncSequence()
        )
    )
}

@MainActor
private func makeDependency(
    clearTransfersUseCase: MockClearTransfersUseCase = MockClearTransfersUseCase()
) -> TransferTabDependency {
    TransferTabDependency(
        inventoryUseCase: MockTransferInventoryUseCase(),
        counterUseCase: MockTransferCounterUseCase(),
        registry: TransferRegistry(),
        locationResolver: StubTransferLocationResolver(),
        finishDateProvider: StubTransferFinishDateProvider(),
        filteringUserTransfers: true,
        clearTransfersUseCase: clearTransfersUseCase
    )
}

private struct StubTransferLocationResolver: TransferLocationResolving {
    func location(for entity: TransferEntity) async -> String? { nil }
}

private struct StubTransferFinishDateProvider: TransferFinishDateProviding {
    func finishDate(forTag tag: Int) -> Date? { nil }
    func recordIfAbsent(tag: Int, date: Date) -> Date { date }
    func removeDates(forTags tags: Set<Int>) {}
}
