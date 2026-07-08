import AsyncAlgorithms
import Foundation
import MEGADomain
import MEGADomainMock
import MEGASwift
import MEGASwiftUI
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

    @Test func pauseAll_showsSnackBarWithResumeAction() {
        let sut = makeSUT(useCase: MockTransferListUseCase(paused: false))

        sut.togglePauseAll()

        #expect(sut.snackBar != nil)
        #expect(sut.snackBar?.action != nil)
    }

    @Test func snackBarResumeAction_resumesAndDismissesSnackBar() {
        let useCase = MockTransferListUseCase(paused: false)
        let sut = makeSUT(useCase: useCase)
        sut.togglePauseAll()

        // Tapping "Resume all" in the snackbar runs its action.
        sut.snackBar?.action?.handler()

        #expect(useCase.resumeTransfersCalledTimes == 1)
        #expect(!sut.isAllPaused)
        #expect(sut.snackBar == nil)
    }

    @Test func resumeViaTopIcon_dismissesSnackBar() {
        let sut = makeSUT(useCase: MockTransferListUseCase(paused: false))
        sut.togglePauseAll() // pause: snackbar shown

        sut.togglePauseAll() // resume via top-bar icon

        #expect(sut.snackBar == nil)
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

@Suite("TransfersListViewModel over-quota banner")
@MainActor
struct TransfersListViewModelOverQuotaTests {

    // MARK: - Initial variant resolution

    @Test func noOverquota_showsNoBanner() {
        let sut = makeSUT()
        #expect(sut.overQuotaBanner == nil)
        #expect(!sut.isTransferOverquota)
    }

    @Test func transferOverquota_showsYellowTransferBanner() {
        let sut = makeSUT(transferQuotaUseCase: MockTransferQuotaUseCase(isOverquota: true))
        #expect(sut.overQuotaBanner == .transfer)
        #expect(sut.isTransferOverquota)
    }

    @Test func storageFull_showsPinkStorageBanner() {
        let sut = makeSUT(accountStorageUseCase: MockAccountStorageUseCase(currentStorageStatus: .full))
        #expect(sut.overQuotaBanner == .storage)
    }

    @Test func storagePaywall_showsPinkStorageBanner() {
        let sut = makeSUT(accountStorageUseCase: MockAccountStorageUseCase(isPaywalled: true))
        #expect(sut.overQuotaBanner == .storage)
    }

    @Test func bothOverquota_showsSingleCombinedBanner() {
        let sut = makeSUT(
            accountStorageUseCase: MockAccountStorageUseCase(currentStorageStatus: .full),
            transferQuotaUseCase: MockTransferQuotaUseCase(isOverquota: true)
        )
        #expect(sut.overQuotaBanner == .both)
    }

    // MARK: - Dismiss

    @Test func dismiss_hidesTransferBanner() {
        let sut = makeSUT(transferQuotaUseCase: MockTransferQuotaUseCase(isOverquota: true))

        sut.dismissOverQuotaBanner()

        #expect(sut.overQuotaBanner == nil)
    }

    @Test func dismiss_whenBoth_fallsBackToNonDismissibleStorageBanner() {
        let sut = makeSUT(
            accountStorageUseCase: MockAccountStorageUseCase(currentStorageStatus: .full),
            transferQuotaUseCase: MockTransferQuotaUseCase(isOverquota: true)
        )

        sut.dismissOverQuotaBanner()

        #expect(sut.overQuotaBanner == .storage)
    }

    @Test func dismiss_doesNotClearTransferOverquotaFlag() {
        let sut = makeSUT(transferQuotaUseCase: MockTransferQuotaUseCase(isOverquota: true))

        sut.dismissOverQuotaBanner()

        // Pause/resume stays disabled even though the banner is hidden.
        #expect(sut.isTransferOverquota)
    }

    // MARK: - Reactive updates

    @Test func observeTransferQuota_showsBannerWhenQuotaHit() async {
        let useCase = MockTransferQuotaUseCase(overquotaUpdates: [true].async.eraseToAnyAsyncSequence())
        let sut = makeSUT(transferQuotaUseCase: useCase)
        #expect(sut.overQuotaBanner == nil)

        await sut.observeTransferQuota()

        #expect(sut.overQuotaBanner == .transfer)
        #expect(sut.isTransferOverquota)
    }

    @Test func observeStorageQuota_reflectsUpdatedStorageStatus() async {
        let useCase = MockAccountStorageUseCase(
            onStorageStatusUpdates: [.full].async.eraseToAnyAsyncSequence(),
            currentStorageStatus: .full
        )
        let sut = makeSUT(accountStorageUseCase: useCase)

        await sut.observeStorageQuota()

        #expect(sut.overQuotaBanner == .storage)
    }

    // MARK: - Upgrade

    @Test func showUpgrade_routesToUpgradeFlow() {
        let router = MockTransferRowRouting()
        let sut = makeSUT(rowRouter: router)

        sut.showUpgrade()

        #expect(router.showUpgradeCallCount == 1)
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
    clearTransfersUseCase: MockClearTransfersUseCase = MockClearTransfersUseCase(),
    accountStorageUseCase: MockAccountStorageUseCase = MockAccountStorageUseCase(),
    transferQuotaUseCase: MockTransferQuotaUseCase = MockTransferQuotaUseCase(),
    rowRouter: MockTransferRowRouting = MockTransferRowRouting()
) -> TransfersListViewModel {
    let seed = TransferTabPresence(
        hasActive: hasActiveTransfers,
        hasCompleted: hasCompletedTransfers,
        hasFailed: hasFailedTransfers
    )
    return TransfersListViewModel(
        dependency: makeDependency(clearTransfersUseCase: clearTransfersUseCase, rowRouter: rowRouter),
        transferListUseCase: useCase,
        monitorPresenceUseCase: MockMonitorTransferTabPresenceUseCase(
            presenceUpdates: presenceUpdates ?? [seed].async.eraseToAnyAsyncSequence()
        ),
        accountStorageUseCase: accountStorageUseCase,
        transferQuotaUseCase: transferQuotaUseCase
    )
}

@MainActor
private func makeDependency(
    clearTransfersUseCase: MockClearTransfersUseCase = MockClearTransfersUseCase(),
    rowRouter: MockTransferRowRouting = MockTransferRowRouting()
) -> TransferTabDependency {
    TransferTabDependency(
        itemsUseCase: MockMonitorTransferTabItemsUseCase(),
        registry: TransferRegistry(),
        locationResolver: StubTransferLocationResolver(),
        finishDateProvider: StubTransferFinishDateProvider(),
        rowRouter: rowRouter,
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
