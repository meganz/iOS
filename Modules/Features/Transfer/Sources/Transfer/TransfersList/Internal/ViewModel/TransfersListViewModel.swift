import Combine
import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGAInfrastructure
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import MEGAUIKit
import SwiftUI

@MainActor
public final class TransfersListViewModel: ObservableObject {
    @Published public var selectedTab: TransfersTab = .active
    @Published public private(set) var isAllPaused: Bool

    /// Select mode. The screen owns only this flag: the selected tags live in
    /// `selection` and are kept in step by the listed tab's view model.
    @Published var editMode: EditMode = .inactive

    /// Shared select-mode selection. The view observes it directly — no
    /// republishing hop — so the count and action enablement land in the same
    /// frame as the tap that changed them.
    let selection = TransferSelection()

    /// Dismisses the screen when it is presented modally; nil when pushed. Owned
    /// by SwiftUI (rendered as the leading Close outside select mode) so select
    /// mode can hand the leading slot to select-all: a presenter-attached UIKit
    /// bar item can only be rendered beside a SwiftUI one, never replaced by it.
    let onClose: (@MainActor () -> Void)?

    /// Drives the cancel-all confirmation alert. Cancel is the only destructive action
    /// that prompts (clear-all and retry-all run immediately, per design).
    @Published var isPresentingCancelAllConfirmation = false

    @Published var snackBar: SnackBar?

    @Published private(set) var presence: TransferTabPresence = .none

    /// The over-quota banner shown above the list, or `nil` when neither quota is
    /// exhausted (or the transfer banner has been dismissed and storage is fine).
    @Published private(set) var overQuotaBanner: OverQuotaBannerType?

    /// Whether transfer quota is currently exhausted. Drives per-row pause/resume
    /// disabling; unaffected by the banner being dismissed.
    @Published private(set) var isTransferOverquota: Bool

    let dependency: TransferTabDependency
    private let transferListUseCase: any TransferListUseCaseProtocol
    private let monitorPresenceUseCase: any MonitorTransferTabPresenceUseCaseProtocol
    private let accountStorageUseCase: any AccountStorageUseCaseProtocol
    private let transferQuotaUseCase: any TransferQuotaUseCaseProtocol
    private let transferControlUseCase: any TransferControlUseCaseProtocol
    private let hapticFeedbackUseCase: any HapticFeedbackUseCaseProtocol

    private var isStorageOverquota: Bool
    /// Session-only: the transfer banner reappears on next launch if still over quota.
    private var isTransferBannerDismissed = false

    init(
        dependency: TransferTabDependency,
        transferListUseCase: some TransferListUseCaseProtocol,
        monitorPresenceUseCase: some MonitorTransferTabPresenceUseCaseProtocol,
        accountStorageUseCase: some AccountStorageUseCaseProtocol,
        transferQuotaUseCase: some TransferQuotaUseCaseProtocol,
        transferControlUseCase: some TransferControlUseCaseProtocol,
        hapticFeedbackUseCase: some HapticFeedbackUseCaseProtocol,
        onClose: (@MainActor () -> Void)? = nil
    ) {
        self.dependency = dependency
        self.transferListUseCase = transferListUseCase
        self.monitorPresenceUseCase = monitorPresenceUseCase
        self.accountStorageUseCase = accountStorageUseCase
        self.transferQuotaUseCase = transferQuotaUseCase
        self.transferControlUseCase = transferControlUseCase
        self.hapticFeedbackUseCase = hapticFeedbackUseCase
        self.onClose = onClose
        self.isAllPaused = transferListUseCase.areTransfersPaused()
        self.isTransferOverquota = transferQuotaUseCase.isOverquota
        self.isStorageOverquota = Self.isOverStorageQuota(accountStorageUseCase)
        self.overQuotaBanner = Self.banner(
            isTransferOverquota: transferQuotaUseCase.isOverquota,
            isStorageOverquota: isStorageOverquota,
            isTransferBannerDismissed: false
        )
    }

    // MARK: - Tab-bar presence

    func observeTabPresence() async {
        for await presence in monitorPresenceUseCase.presenceUpdates {
            self.presence = presence
            // Selecting on a tab that just emptied would strand the user on a
            // select-mode bar over an empty state, with nothing left to act on.
            if isSelectModeActive, isCurrentTabEmpty {
                exitSelectMode()
            }
        }
    }

    // MARK: - Over-quota banner

    func observeStorageQuota() async {
        for await _ in accountStorageUseCase.onStorageStatusUpdates {
            isStorageOverquota = Self.isOverStorageQuota(accountStorageUseCase)
            recomputeBanner()
        }
    }

    func observeTransferQuota() async {
        for await isOverquota in transferQuotaUseCase.overquotaUpdates {
            isTransferOverquota = isOverquota
            recomputeBanner()
        }
    }

    /// Hides the transfer/combined banner for the current session. The storage banner is
    /// never dismissible, so a lingering storage over-quota falls back to its pink banner.
    func dismissOverQuotaBanner() {
        isTransferBannerDismissed = true
        recomputeBanner()
    }

    func showUpgrade() {
        dependency.rowRouter.showUpgrade()
    }

    private func recomputeBanner() {
        overQuotaBanner = Self.banner(
            isTransferOverquota: isTransferOverquota,
            isStorageOverquota: isStorageOverquota,
            isTransferBannerDismissed: isTransferBannerDismissed
        )
    }

    private static func isOverStorageQuota(_ useCase: some AccountStorageUseCaseProtocol) -> Bool {
        useCase.currentStorageStatus == .full || useCase.isPaywalled
    }

    private static func banner(
        isTransferOverquota: Bool,
        isStorageOverquota: Bool,
        isTransferBannerDismissed: Bool
    ) -> OverQuotaBannerType? {
        let transfer = isTransferOverquota && !isTransferBannerDismissed
        switch (transfer, isStorageOverquota) {
        case (true, true): return .both
        case (true, false): return .transfer
        case (false, true): return .storage
        case (false, false): return nil
        }
    }

    public var hasActiveTransfers: Bool { presence.hasActive }
    public var hasCompletedTransfers: Bool { presence.hasCompleted }
    public var hasFailedTransfers: Bool { presence.hasFailed }

    public var hasAnyTransfers: Bool {
        presence.hasActive || presence.hasCompleted || presence.hasFailed
    }

    public var isCurrentTabEmpty: Bool {
        switch selectedTab {
        case .active: !presence.hasActive
        case .completed: !presence.hasCompleted
        case .failed: !presence.hasFailed
        }
    }

    func togglePauseAll() {
        if isAllPaused {
            resumeAll()
        } else {
            pauseAll()
        }
    }

    private func pauseAll() {
        transferListUseCase.pauseTransfers()
        isAllPaused = true
        snackBar = SnackBar(
            message: Strings.Localizable.Transfers.Snackbar.allPaused,
            layout: .horizontal,
            action: .init(title: Strings.Localizable.resumeAll) { [weak self] in
                self?.resumeAll()
            }
        )
    }

    private func resumeAll() {
        transferListUseCase.resumeTransfers()
        isAllPaused = false
        snackBar = nil
    }

    // MARK: - Swipe-cancel undo

    /// Shows the undo snackbar after a row swipe-cancel. The SDK cannot resurrect a
    /// cancelled transfer, so Undo re-queues it as a fresh transfer (retry) and clears
    /// the Cancelled entry the cancel left on the Failed tab.
    func didCancelTransfer(_ transfer: TransferEntity) {
        snackBar = SnackBar(
            message: Strings.Localizable.transferCancelled,
            layout: .horizontal,
            action: .init(title: Strings.Localizable.General.undo) { [weak self] in
                Task { await self?.undoCancel(transfer) }
            }
        )
    }

    func undoCancel(_ transfer: TransferEntity) async {
        snackBar = nil
        do {
            try await transferControlUseCase.retryTransfer(transfer)
            dependency.clearTransfersUseCase.clearTransfer(tag: transfer.tag)
        } catch {
            MEGALogError("[Transfer] undo cancel failed for tag \(transfer.tag): \(error)")
        }
    }

    // MARK: - More menu

    /// Tab-specific actions for the top-bar More menu. Each action is only offered
    /// when the current tab has rows to act on, so an empty list means the More
    /// button should be hidden (see `showsMoreMenu`).
    var menuActions: [TransferMoreMenuAction] {
        switch selectedTab {
        case .active:
            presence.hasActive ? [.select, .cancelAll] : []
        case .completed:
            presence.hasCompleted ? [.select, .clearAll] : []
        case .failed:
            presence.hasFailed ? [.select, .retryAll, .clearAll] : []
        }
    }

    /// The More button is hidden when the current tab has no actions, to avoid
    /// presenting an empty menu.
    var showsMoreMenu: Bool {
        !menuActions.isEmpty
    }

    // MARK: - Select mode

    var isSelectModeActive: Bool {
        editMode.isEditing
    }

    func enterSelectMode() {
        editMode = .active
    }

    func enterSelectMode(preselecting tag: Int) {
        guard !isSelectModeActive else { return }
        hapticFeedbackUseCase.generateHapticFeedback(.light)
        editMode = .active
        selection.select(tag)
    }

    /// The Done button, and the fallback for when the listed tab runs dry while
    /// selecting (e.g. every selected Active transfer finishes).
    func exitSelectMode() {
        editMode = .inactive
        selection.clear()
    }

    // MARK: - Select-mode actions
    //
    // Rendered and enabled-when-something-is-selected here; running them on the
    // selected subset lands with IOS-12220. Until then the screen ships behind
    // the `newTransfers` feature flag, so the inert buttons stay internal.

    /// Active tab: cancel the selected transfers.
    func cancelSelectedTransfers() {
        // IOS-12220
    }

    /// Completed and Failed tabs: clear the selected transfers.
    func clearSelectedTransfers() {
        // IOS-12220
    }

    /// Failed tab: retry the selected transfers.
    func retrySelectedTransfers() {
        // IOS-12220
    }

    // MARK: - Confirmation dialog

    /// Cancel is the only action that prompts. Opens the dialog from the More menu;
    /// the selected-subset variant arrives with IOS-12220.
    func requestCancelAllConfirmation() {
        isPresentingCancelAllConfirmation = true
    }

    /// Runs the confirmed cancel-all. SwiftUI clears `isPresentingCancelAllConfirmation`
    /// when the alert dismisses, so no manual reset is needed here.
    func confirmCancelAll() {
        cancelAllTransfers()
    }

    // MARK: - Bulk actions

    /// Cancels every ongoing transfer. The Active list empties reactively as the SDK
    /// reports each transfer finished, so no manual refresh is needed here. Cancelled
    /// transfers then surface on the Failed tab.
    private func cancelAllTransfers() {
        transferListUseCase.cancelTransfers()
    }
    
    func clearAllTransfers() {
        switch selectedTab {
        case .completed:
            dependency.clearTransfersUseCase.clearCompletedTransfers()
        case .failed:
            dependency.clearTransfersUseCase.clearFailedTransfers()
        case .active:
            return
        }
    }

    /// Re-queues every retryable transfer the Failed tab shows (uploads whose staged
    /// source is gone are skipped and their rows stay), clears the re-queued entries
    /// in one pass, and confirms with the retry snackbar. Runs immediately with no
    /// confirmation, like clear-all. Scoped to the tab's own snapshot: the
    /// completed-transfers cache also holds transfers the tab hides (app-internal
    /// downloads, folder and streaming transfers), which must not be retried.
    func retryAllTransfers() async {
        let visibleTags = Set(await dependency.itemsUseCase.snapshot(for: .failed).map(\.tag))
        guard !visibleTags.isEmpty else { return }
        let retriedTags = transferControlUseCase.retryTransfers(tags: visibleTags)
        guard !retriedTags.isEmpty else { return }
        dependency.clearTransfersUseCase.clearTransfers(tags: retriedTags)
        didRetryTransfers()
    }

    /// Shows the retry snackbar. Fired by every retry entry point: the per-row sheet
    /// and leading swipe (via `onTransferRetried`) and Retry all.
    func didRetryTransfers() {
        snackBar = SnackBar(message: Strings.Localizable.retrying)
    }
}
