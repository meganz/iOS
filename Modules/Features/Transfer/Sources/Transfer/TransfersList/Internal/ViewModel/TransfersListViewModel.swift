import Combine
import Foundation
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import MEGAUIKit

@MainActor
public final class TransfersListViewModel: ObservableObject {
    @Published public var selectedTab: TransfersTab = .active
    @Published public private(set) var isAllPaused: Bool

    /// Drives the cancel-all confirmation alert. Cancel is the only destructive action
    /// that prompts (clear-all and retry-all run immediately, per design).
    @Published var isPresentingCancelAllConfirmation = false

    @Published var snackBar: SnackBar?

    @Published private(set) var presence: TransferTabPresence = .none

    let dependency: TransferTabDependency
    private let transferListUseCase: any TransferListUseCaseProtocol
    private let monitorPresenceUseCase: any MonitorTransferTabPresenceUseCaseProtocol

    init(
        dependency: TransferTabDependency,
        transferListUseCase: some TransferListUseCaseProtocol,
        monitorPresenceUseCase: some MonitorTransferTabPresenceUseCaseProtocol
    ) {
        self.dependency = dependency
        self.transferListUseCase = transferListUseCase
        self.monitorPresenceUseCase = monitorPresenceUseCase
        self.isAllPaused = transferListUseCase.areTransfersPaused()
    }

    // MARK: - Tab-bar presence

    func observeTabPresence() async {
        for await presence in monitorPresenceUseCase.presenceUpdates {
            self.presence = presence
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

    func enterSelectMode() {
        // Select mode: IOS-11933
    }

    // MARK: - Confirmation dialog

    /// Cancel is the only action that prompts. Opens the dialog from the More menu;
    /// the selected-subset variant arrives with select mode (IOS-11933).
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

    func retryAllTransfers() {
        // Retry-all: IOS-11943
    }
}
