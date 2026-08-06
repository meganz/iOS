import AsyncAlgorithms
import Foundation
import MEGADomain
import MEGADomainMock
import MEGAInfrastructure
import MEGAInfrastructureMocks
import MEGASwift
import MEGASwiftUI
import SwiftUI
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

    @Test func requestCancelAll_presentsDialogScopedToEveryTransfer() {
        let sut = makeSUT()

        sut.confirmCancelAllTransfers()

        #expect(sut.presentingCancelConfirmation == .all)
    }

    @Test func confirmCancelAll_cancelsTransfers() async {
        let useCase = MockTransferListUseCase()
        let sut = makeSUT(useCase: useCase)
        sut.confirmCancelAllTransfers()

        await sut.confirmCancel(.all)

        #expect(useCase.cancelTransfersCalledTimes == 1)
    }

    @Test func dismissingDialog_runsNoAction() {
        let useCase = MockTransferListUseCase()
        let sut = makeSUT(useCase: useCase)
        sut.confirmCancelAllTransfers()

        // Tapping Dismiss flips the binding without confirming.
        sut.presentingCancelConfirmation = nil

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

@Suite("TransfersListViewModel select mode")
@MainActor
struct TransfersListViewModelSelectModeTests {

    @Test func freshlyConstructed_isNotSelecting() {
        let sut = makeSUT()

        #expect(!sut.isSelectModeActive)
        #expect(sut.selection.isEmpty)
    }

    @Test func enterSelectMode_activatesEditMode() {
        let sut = makeSUT()

        sut.enterSelectMode()

        #expect(sut.isSelectModeActive)
        #expect(sut.editMode == .active)
    }

    @Test func enterSelectModePreselecting_activatesEditModeWithThatRowTicked() {
        let sut = makeSUT()

        sut.enterSelectMode(preselecting: 7)

        #expect(sut.isSelectModeActive)
        #expect(sut.selection.selectedTags == [7])
        #expect(sut.selection.count == 1)
    }

    @Test func enterSelectModePreselecting_firesHapticFeedbackOnCommit() {
        let haptics = MockHapticFeedbackUseCase()
        let sut = makeSUT(hapticFeedbackUseCase: haptics)

        sut.enterSelectMode(preselecting: 7)

        #expect(haptics.feedbacks == [HapticFeedbackType.light])
    }

    @Test func enterSelectModePreselecting_whileAlreadySelecting_isIgnored() {
        // In select mode a press belongs to the checkbox; re-entering would tick a
        // second row on a gesture the user reads as a plain tap.
        let haptics = MockHapticFeedbackUseCase()
        let sut = makeSUT(hapticFeedbackUseCase: haptics)
        sut.enterSelectMode(preselecting: 7)

        sut.enterSelectMode(preselecting: 9)

        #expect(sut.selection.selectedTags == [7])
        // Only the first entry fired; the second call short-circuited.
        #expect(haptics.feedbacks == [HapticFeedbackType.light])
    }

    @Test func exitSelectMode_deactivatesEditModeAndClearsTheSelection() {
        let sut = makeSUT()
        sut.enterSelectMode()
        sut.selection.selectedTags = [1, 2]

        sut.exitSelectMode()

        #expect(!sut.isSelectModeActive)
        #expect(sut.selection.isEmpty)
    }

    @Test func presenceUpdate_emptyingTheSelectedTab_exitsSelectMode() async {
        // Every selected Active transfer finishing must not strand the user on a
        // select-mode bar above an empty state.
        let updates = [
            TransferTabPresence(hasActive: false, hasCompleted: true, hasFailed: false)
        ].async.eraseToAnyAsyncSequence()
        let sut = makeSUT(presenceUpdates: updates)
        sut.selectedTab = .active
        sut.enterSelectMode()
        sut.selection.selectedTags = [1]

        await sut.observeTabPresence()

        #expect(!sut.isSelectModeActive)
        #expect(sut.selection.isEmpty)
    }

    @Test func presenceUpdate_keepingTheSelectedTabPopulated_staysInSelectMode() async {
        let updates = [
            TransferTabPresence(hasActive: true, hasCompleted: false, hasFailed: false)
        ].async.eraseToAnyAsyncSequence()
        let sut = makeSUT(presenceUpdates: updates)
        sut.selectedTab = .active
        sut.enterSelectMode()
        sut.selection.selectedTags = [1]

        await sut.observeTabPresence()

        #expect(sut.isSelectModeActive)
        #expect(sut.selection.selectedTags == [1])
    }

    @Test func onClose_isNilUnlessAModalPresenterSuppliesIt() {
        #expect(makeSUT().onClose == nil)

        var closed = false
        let modal = makeSUT(onClose: { closed = true })
        modal.onClose?()

        #expect(closed)
    }
}

@Suite("TransfersListViewModel select-mode actions")
@MainActor
struct TransfersListViewModelSelectModeActionsTests {

    // MARK: - Cancel selected

    @Test func requestCancelSelected_presentsDialogScopedToTheSelection() {
        let sut = makeSUT()
        sut.enterSelectMode()

        sut.confirmCancelSelectedTransfers()

        #expect(sut.presentingCancelConfirmation == .selected)
        // Nothing runs until the dialog is confirmed.
        #expect(sut.isSelectModeActive)
    }

    @Test func confirmCancelSelected_cancelsOnlyTheSelectedRowsAndExitsSelectMode() async {
        let transferControlUseCase = MockTransferControlUseCase()
        let itemsUseCase = MockMonitorTransferTabItemsUseCase(
            snapshot: [TransferEntity(tag: 3), TransferEntity(tag: 5), TransferEntity(tag: 8)]
        )
        let sut = makeSUT(transferControlUseCase: transferControlUseCase, itemsUseCase: itemsUseCase)
        sut.selectedTab = .active
        sut.enterSelectMode()
        sut.selection.selectedTags = [3, 5]

        await sut.confirmCancel(.selected)

        #expect(transferControlUseCase.cancelledTransfers.map(\.tag) == [3, 5])
        #expect(!sut.isSelectModeActive)
        #expect(sut.selection.isEmpty)
        // Bulk cancel has no Undo: the dialog is the safeguard.
        #expect(sut.snackBar == nil)
    }

    @Test func confirmCancelSelected_skipsSelectedTagsThatLeftTheTab() async {
        let transferControlUseCase = MockTransferControlUseCase()
        // Tag 3 finished while the user was selecting, so it is gone from the inventory.
        let itemsUseCase = MockMonitorTransferTabItemsUseCase(snapshot: [TransferEntity(tag: 5)])
        let sut = makeSUT(transferControlUseCase: transferControlUseCase, itemsUseCase: itemsUseCase)
        sut.enterSelectMode()
        sut.selection.selectedTags = [3, 5]

        await sut.confirmCancel(.selected)

        #expect(transferControlUseCase.cancelledTransfers.map(\.tag) == [5])
    }

    @Test func confirmCancelSelected_withNothingSelected_cancelsNothingAndStillExits() async {
        let transferControlUseCase = MockTransferControlUseCase()
        let itemsUseCase = MockMonitorTransferTabItemsUseCase(snapshot: [TransferEntity(tag: 3)])
        let sut = makeSUT(transferControlUseCase: transferControlUseCase, itemsUseCase: itemsUseCase)
        sut.enterSelectMode()

        await sut.confirmCancel(.selected)

        #expect(transferControlUseCase.cancelledTransfers.isEmpty)
        #expect(!sut.isSelectModeActive)
    }

    @Test func confirmCancelSelected_whenTheEngineRejectsOneCancel_runsTheRestAnyway() async {
        let transferControlUseCase = MockTransferControlUseCase()
        transferControlUseCase.cancelError = CancellationError()
        let itemsUseCase = MockMonitorTransferTabItemsUseCase(
            snapshot: [TransferEntity(tag: 3), TransferEntity(tag: 5)]
        )
        let sut = makeSUT(transferControlUseCase: transferControlUseCase, itemsUseCase: itemsUseCase)
        sut.enterSelectMode()
        sut.selection.selectedTags = [3, 5]

        await sut.confirmCancel(.selected)

        #expect(transferControlUseCase.cancelledTransfers.map(\.tag) == [3, 5])
        #expect(!sut.isSelectModeActive)
    }

    // MARK: - Clear selected

    @Test func clearSelected_clearsOnlyTheSelectedTagsExitsSelectModeAndShowsNoSnackBar() {
        let clearUseCase = MockClearTransfersUseCase()
        let sut = makeSUT(clearTransfersUseCase: clearUseCase)
        sut.selectedTab = .completed
        sut.enterSelectMode()
        sut.selection.selectedTags = [3, 5]

        sut.clearSelectedTransfers()

        #expect(clearUseCase.clearedTransferTagSets == [[3, 5]])
        // Never the whole tab.
        #expect(clearUseCase.clearCompletedTransfersCalledTimes == 0)
        #expect(clearUseCase.clearFailedTransfersCalledTimes == 0)
        #expect(!sut.isSelectModeActive)
        #expect(sut.selection.isEmpty)
        #expect(sut.snackBar == nil)
    }

    @Test func clearSelected_withNothingSelected_clearsNothingAndStillExits() {
        let clearUseCase = MockClearTransfersUseCase()
        let sut = makeSUT(clearTransfersUseCase: clearUseCase)
        sut.enterSelectMode()

        sut.clearSelectedTransfers()

        #expect(clearUseCase.clearedTransferTagSets.isEmpty)
        #expect(!sut.isSelectModeActive)
    }

    // MARK: - Retry selected

    @Test func retrySelected_requeuesTheSelectionClearsTheRequeuedEntriesShowsSnackBarAndExits() {
        let transferControlUseCase = MockTransferControlUseCase()
        // Tag 8's upload source is gone: requested but not re-queued, so not cleared.
        transferControlUseCase.retryTransfersResult = [3, 5]
        let clearUseCase = MockClearTransfersUseCase()
        let sut = makeSUT(
            clearTransfersUseCase: clearUseCase,
            transferControlUseCase: transferControlUseCase
        )
        sut.selectedTab = .failed
        sut.enterSelectMode()
        sut.selection.selectedTags = [3, 5, 8]

        sut.retrySelectedTransfers()

        #expect(transferControlUseCase.retryTransfersReceivedTagSets == [[3, 5, 8]])
        #expect(clearUseCase.clearedTransferTagSets == [[3, 5]])
        #expect(sut.snackBar != nil)
        #expect(sut.snackBar?.action == nil)
        #expect(!sut.isSelectModeActive)
        #expect(sut.selection.isEmpty)
    }

    @Test func retrySelected_whenNothingIsRetryable_clearsNothingAndShowsNoSnackBar() {
        let transferControlUseCase = MockTransferControlUseCase()
        let clearUseCase = MockClearTransfersUseCase()
        let sut = makeSUT(
            clearTransfersUseCase: clearUseCase,
            transferControlUseCase: transferControlUseCase
        )
        sut.enterSelectMode()
        sut.selection.selectedTags = [8]

        sut.retrySelectedTransfers()

        #expect(transferControlUseCase.retryTransfersReceivedTagSets == [[8]])
        #expect(clearUseCase.clearedTransferTagSets.isEmpty)
        #expect(sut.snackBar == nil)
        #expect(!sut.isSelectModeActive)
    }

    @Test func retrySelected_withNothingSelected_retriesNothingAndStillExits() {
        let transferControlUseCase = MockTransferControlUseCase()
        let sut = makeSUT(transferControlUseCase: transferControlUseCase)
        sut.enterSelectMode()

        sut.retrySelectedTransfers()

        #expect(transferControlUseCase.retryTransfersReceivedTagSets.isEmpty)
        #expect(!sut.isSelectModeActive)
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

@Suite("TransfersListViewModel swipe-cancel undo")
@MainActor
struct TransfersListViewModelSwipeCancelTests {

    @Test func didCancelTransfer_showsSnackBarWithUndoAction() {
        let sut = makeSUT()

        sut.didCancelTransfer(TransferEntity(tag: 7))

        #expect(sut.snackBar != nil)
        #expect(sut.snackBar?.action?.title == "Undo")
    }

    @Test func undoCancel_retriesTransferClearsCancelledEntryAndDismissesSnackBar() async {
        let transferControlUseCase = MockTransferControlUseCase()
        let clearUseCase = MockClearTransfersUseCase()
        let sut = makeSUT(clearTransfersUseCase: clearUseCase, transferControlUseCase: transferControlUseCase)
        let transfer = TransferEntity(tag: 7)
        sut.didCancelTransfer(transfer)

        await sut.undoCancel(transfer)

        #expect(transferControlUseCase.retriedTransfers.map(\.tag) == [7])
        #expect(clearUseCase.clearedTransferTags == [7])
        #expect(sut.snackBar == nil)
    }

    @Test func undoCancel_retryFailureIsSwallowedAndDoesNotClear() async {
        let transferControlUseCase = MockTransferControlUseCase()
        transferControlUseCase.retryError = CancellationError()
        let clearUseCase = MockClearTransfersUseCase()
        let sut = makeSUT(clearTransfersUseCase: clearUseCase, transferControlUseCase: transferControlUseCase)
        let transfer = TransferEntity(tag: 7)

        await sut.undoCancel(transfer)

        #expect(clearUseCase.clearedTransferTags.isEmpty)
    }
}

@Suite("TransfersListViewModel retry all")
@MainActor
struct TransfersListViewModelRetryAllTests {

    @Test func retryAll_requeuesTheFailedTabRowsClearsTheRequeuedEntriesAndShowsSnackBar() async {
        let transferControlUseCase = MockTransferControlUseCase()
        // Tag 8's upload source is gone: requested but not re-queued, so not cleared.
        transferControlUseCase.retryTransfersResult = [3, 5]
        let clearUseCase = MockClearTransfersUseCase()
        let itemsUseCase = MockMonitorTransferTabItemsUseCase(
            snapshot: [TransferEntity(tag: 3), TransferEntity(tag: 5), TransferEntity(tag: 8)]
        )
        let sut = makeSUT(
            clearTransfersUseCase: clearUseCase,
            transferControlUseCase: transferControlUseCase,
            itemsUseCase: itemsUseCase
        )

        await sut.retryAllTransfers()

        #expect(transferControlUseCase.retryTransfersReceivedTagSets == [[3, 5, 8]])
        #expect(clearUseCase.clearedTransferTagSets == [[3, 5]])
        #expect(sut.snackBar != nil)
        #expect(sut.snackBar?.action == nil)
    }

    @Test func retryAll_withNoRowsOnTheFailedTab_retriesNothing() async {
        let transferControlUseCase = MockTransferControlUseCase()
        let clearUseCase = MockClearTransfersUseCase()
        let sut = makeSUT(clearTransfersUseCase: clearUseCase, transferControlUseCase: transferControlUseCase)

        await sut.retryAllTransfers()

        #expect(transferControlUseCase.retryTransfersReceivedTagSets.isEmpty)
        #expect(clearUseCase.clearedTransferTagSets.isEmpty)
        #expect(sut.snackBar == nil)
    }

    @Test func retryAll_whenNoRowIsRetryable_clearsNothingAndShowsNoSnackBar() async {
        let transferControlUseCase = MockTransferControlUseCase()
        let clearUseCase = MockClearTransfersUseCase()
        let itemsUseCase = MockMonitorTransferTabItemsUseCase(snapshot: [TransferEntity(tag: 8)])
        let sut = makeSUT(
            clearTransfersUseCase: clearUseCase,
            transferControlUseCase: transferControlUseCase,
            itemsUseCase: itemsUseCase
        )

        await sut.retryAllTransfers()

        #expect(clearUseCase.clearedTransferTagSets.isEmpty)
        #expect(sut.snackBar == nil)
    }

    @Test func didRetryTransfers_showsPlainSnackBar() {
        let sut = makeSUT()

        sut.didRetryTransfers()

        #expect(sut.snackBar != nil)
        #expect(sut.snackBar?.action == nil)
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
    rowRouter: MockTransferRowRouting = MockTransferRowRouting(),
    transferControlUseCase: MockTransferControlUseCase = MockTransferControlUseCase(),
    itemsUseCase: MockMonitorTransferTabItemsUseCase = MockMonitorTransferTabItemsUseCase(),
    hapticFeedbackUseCase: MockHapticFeedbackUseCase = MockHapticFeedbackUseCase(),
    onClose: (@MainActor () -> Void)? = nil
) -> TransfersListViewModel {
    let seed = TransferTabPresence(
        hasActive: hasActiveTransfers,
        hasCompleted: hasCompletedTransfers,
        hasFailed: hasFailedTransfers
    )
    return TransfersListViewModel(
        dependency: makeDependency(
            clearTransfersUseCase: clearTransfersUseCase,
            rowRouter: rowRouter,
            itemsUseCase: itemsUseCase
        ),
        transferListUseCase: useCase,
        monitorPresenceUseCase: MockMonitorTransferTabPresenceUseCase(
            presenceUpdates: presenceUpdates ?? [seed].async.eraseToAnyAsyncSequence()
        ),
        accountStorageUseCase: accountStorageUseCase,
        transferQuotaUseCase: transferQuotaUseCase,
        transferControlUseCase: transferControlUseCase,
        hapticFeedbackUseCase: hapticFeedbackUseCase,
        onClose: onClose
    )
}

@MainActor
private func makeDependency(
    clearTransfersUseCase: MockClearTransfersUseCase = MockClearTransfersUseCase(),
    rowRouter: MockTransferRowRouting = MockTransferRowRouting(),
    itemsUseCase: MockMonitorTransferTabItemsUseCase = MockMonitorTransferTabItemsUseCase()
) -> TransferTabDependency {
    TransferTabDependency(
        itemsUseCase: itemsUseCase,
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
