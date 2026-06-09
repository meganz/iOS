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

    /// Shared dependencies for the screen, also handed to each tab to build its own
    /// `TransferTabViewModel`. The parent VM reads `inventoryUseCase` /
    /// `filteringUserTransfers` from it to seed presence.
    let dependency: TransferTabDependency
    private let transfersListenerUseCase: any TransfersListenerUseCaseProtocol
    private var cancellables: Set<AnyCancellable> = []

    /// Production initializer. Tab presence (`hasActiveTransfers` /
    /// `hasCompletedTransfers` / `hasFailedTransfers`) is driven by each tab reporting
    /// its live item count back through the `active/completed/failedPresence`
    /// bindings, observed in `observePresence()`.
    init(
        dependency: TransferTabDependency,
        transfersListenerUseCase: some TransfersListenerUseCaseProtocol
    ) {
        self.hasActiveTransfers = false
        self.hasCompletedTransfers = false
        self.hasFailedTransfers = false
        self.dependency = dependency
        self.transfersListenerUseCase = transfersListenerUseCase
        self.isAllPaused = transfersListenerUseCase.areTransfersPaused()

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
        hasCompletedTransfers = dependency.inventoryUseCase
            .completedTransfers(filteringUserTransfers: dependency.filteringUserTransfers)
            .contains(where: \.isVisibleOnCompletedTab)
    }

    /// Seeds Failed presence from the inventory, for the same reason as
    /// `seedCompletedPresence()`: the Failed tab's live count is only available while
    /// its view is mounted, so a user whose only transfers are failed/cancelled needs
    /// the inventory to keep the tab bar visible. Call once on appear.
    public func seedFailedPresence() {
        hasFailedTransfers = dependency.inventoryUseCase
            .completedTransfers(filteringUserTransfers: dependency.filteringUserTransfers)
            .contains(where: \.isVisibleOnFailedTab)
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
    /// but never clearing on zero avoids flickering the tab bar during that window
    /// (clearing completed transfers is not yet supported, so the list only grows).
    private func updateCompletedPresence(count: Int) {
        if count > 0 {
            hasCompletedTransfers = true
        }
    }

    /// Upgrade-only, for the same reason as `updateCompletedPresence(count:)`:
    /// confirm presence on a non-zero count but never clear on the stale 0 emitted
    /// while `FailedTransfersTab` mounts (clearing failed transfers is not yet
    /// supported, so the list only grows).
    private func updateFailedPresence(count: Int) {
        if count > 0 {
            hasFailedTransfers = true
        }
    }

    /// Pause-all / resume-all toggle. Routes through `TransfersListenerUseCase`,
    /// which writes the persisted `transfersPaused` / `queuedTransfersPaused` flags
    /// (MEGAPreference) and forwards to the SDK. The `isAllPaused` flag updates
    /// optimistically — matches the existing use case contract, which doesn't await
    /// the SDK's request finish before persisting.
    public func togglePauseAll() {
        if isAllPaused {
            transfersListenerUseCase.resumeTransfers()
        } else {
            transfersListenerUseCase.pauseTransfers()
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

    func cancelAllTransfers() {
        // Confirmation dialog + cancel-all: IOS-11934
    }

    func clearAllTransfers() {
        // Confirmation dialog + clear-all: IOS-11934
    }

    func retryAllTransfers() {
        // Retry-all: IOS-11943
    }
}
