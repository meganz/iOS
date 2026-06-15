import Combine
import Foundation
import MEGADomain
import MEGAUIComponent
import MEGAUIKit

@MainActor
public final class TransfersListViewModel: ObservableObject {
    @Published public var selectedTab: TransfersTab = .active

    @Published public private(set) var hasActiveTransfers: Bool
    @Published public private(set) var hasCompletedTransfers: Bool
    @Published public private(set) var hasFailedTransfers: Bool
    @Published public private(set) var isAllPaused: Bool

    /// Live item counts reported up by each mounted tab through a `@Binding`. The
    /// subscriptions in `observePresence()` translate them into the `has*Transfers`
    /// flags that drive the tab bar.
    @Published var activePresence: Int = 0
    @Published var completedPresence: Int = 0
    @Published var failedPresence: Int = 0
    
    /// Drives the cancel-all confirmation alert. Cancel is the only destructive action
    /// that prompts (clear-all and retry-all run immediately, per design).
    @Published var isPresentingCancelAllConfirmation = false

    /// Shared dependencies for the screen, handed to each tab to build its own
    /// `TransferTabViewModel`.
    let dependency: TransferTabDependency
    private let transferListUseCase: any TransferListUseCaseProtocol
    private var cancellables: Set<AnyCancellable> = []

    /// Production initializer. Tab presence (`hasActiveTransfers` /
    /// `hasCompletedTransfers` / `hasFailedTransfers`) is driven by each tab reporting
    /// its live item count back through the `active/completed/failedPresence`
    /// bindings, observed in `observePresence()`.
    init(
        dependency: TransferTabDependency,
        transferListUseCase: some TransferListUseCaseProtocol
    ) {
        self.hasActiveTransfers = false
        self.hasCompletedTransfers = false
        self.hasFailedTransfers = false
        self.dependency = dependency
        self.transferListUseCase = transferListUseCase
        self.isAllPaused = transferListUseCase.areTransfersPaused()

        observePresence()
    }

    /// Drops the synthetic value `@Published` emits on subscription so only real
    /// counts reported by a mounted tab reach the `update*Presence(count:)` handlers.
    private func observePresence() {
        $activePresence
            .dropFirst()
            .sink { [weak self] in self?.updateActivePresence(count: $0) }
            .store(in: &cancellables)

        $completedPresence
            .dropFirst()
            .sink { [weak self] in self?.updateCompletedPresence(count: $0) }
            .store(in: &cancellables)

        $failedPresence
            .dropFirst()
            .sink { [weak self] in self?.updateFailedPresence(count: $0) }
            .store(in: &cancellables)
    }

    public var hasAnyTransfers: Bool {
        hasActiveTransfers || hasCompletedTransfers || hasFailedTransfers
    }

    public var isCurrentTabEmpty: Bool {
        switch selectedTab {
        case .active: !hasActiveTransfers
        case .completed: !hasCompletedTransfers
        case .failed: !hasFailedTransfers
        }
    }

    /// Seeds Completed presence so the tab bar is correct at launch even before the
    /// Completed tab is opened. A tab's live item count is only available while its
    /// view is mounted, so the inventory is the only source of truth for a user
    /// whose sole transfers are completed ones. Call once on appear.
    public func seedCompletedPresence() {
        hasCompletedTransfers = transferListUseCase.hasCompletedTransfers()
    }

    /// Seeds Failed presence from the inventory, for the same reason as
    /// `seedCompletedPresence()`: the Failed tab's live count is only available while
    /// its view is mounted, so a user whose only transfers are failed/cancelled needs
    /// the inventory to keep the tab bar visible. Call once on appear.
    public func seedFailedPresence() {
        hasFailedTransfers = transferListUseCase.hasFailedTransfers()
    }

    /// Tracks Active presence from the tab's live item count, reported by
    /// `ActiveTransfersTab`. When it hits 0, re-seed Completed and Failed from
    /// inventory so a transfer that just finished here keeps the tab bar visible
    /// (those tabs aren't mounted to observe the finish themselves).
    private func updateActivePresence(count: Int) {
        hasActiveTransfers = count > 0
        if count == 0 {
            seedCompletedPresence()
            seedFailedPresence()
        }
    }

    /// Upgrade-only: while `CompletedTransfersTab` mounts, its count sequence emits a
    /// stale 0 before `task()` populates it. Confirming presence on a non-zero count
    /// but never clearing on zero avoids flickering the tab bar during that window. A
    /// genuine clear is handled out-of-band by `clearAllTransfers()`, which flips the
    /// flag to false directly, so this observer never needs to clear it.
    private func updateCompletedPresence(count: Int) {
        if count > 0 {
            hasCompletedTransfers = true
        }
    }

    /// Upgrade-only, for the same reason as `updateCompletedPresence(count:)`:
    /// confirm presence on a non-zero count but never clear on the stale 0 emitted
    /// while `FailedTransfersTab` mounts. A genuine clear flips the flag to false
    /// directly in `clearAllTransfers()`.
    private func updateFailedPresence(count: Int) {
        if count > 0 {
            hasFailedTransfers = true
        }
    }
    
    public func togglePauseAll() {
        if isAllPaused {
            transferListUseCase.resumeTransfers()
        } else {
            transferListUseCase.pauseTransfers()
        }
        isAllPaused.toggle()
    }

    // MARK: - More menu

    /// Tab-specific actions for the top-bar More menu. Each action is only offered
    /// when the current tab has rows to act on, so an empty list means the More
    /// button should be hidden (see `showsMoreMenu`).
    var menuActions: [TransferMoreMenuAction] {
        switch selectedTab {
        case .active:
            hasActiveTransfers ? [.select, .cancelAll] : []
        case .completed:
            hasCompletedTransfers ? [.select, .clearAll] : []
        case .failed:
            hasFailedTransfers ? [.select, .retryAll, .clearAll] : []
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

    /// Clears the current tab's list with no confirmation (per design). The tab
    /// presence flag is flipped manually so `hasAnyTransfers` (which drives the tab
    /// bar and the all-empty "No transfers" overlay) and `menuActions` (which hides
    /// the More button) update immediately. The flip is manual because the
    /// Completed/Failed observers are upgrade-only (they never clear on a zero count).
    /// Clearing is a silent SDK cache removal that fires no transfer delegate event, so
    /// the mounted tab's Search list wouldn't re-query on its own; the clear use case
    /// emits a `clearedSignals` ping (observed by the provider) that re-snapshots the
    /// now-empty cache.
    func clearAllTransfers() {
        switch selectedTab {
        case .completed:
            dependency.clearTransfersUseCase.clearCompletedTransfers()
            hasCompletedTransfers = false
        case .failed:
            dependency.clearTransfersUseCase.clearFailedTransfers()
            hasFailedTransfers = false
        case .active:
            return
        }
    }

    func retryAllTransfers() {
        // Retry-all: IOS-11943
    }
}
