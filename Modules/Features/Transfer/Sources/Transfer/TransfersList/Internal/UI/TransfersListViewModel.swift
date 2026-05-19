import Foundation
import MEGAL10n

@MainActor
public final class TransfersListViewModel: ObservableObject {
    @Published public var selectedTab: TransfersTab = .active

    @Published public var hasActiveTransfers: Bool
    @Published public var hasCompletedTransfers: Bool
    @Published public var hasFailedTransfers: Bool

    public init(
        hasActiveTransfers: Bool = false,
        hasCompletedTransfers: Bool = false,
        hasFailedTransfers: Bool = false
    ) {
        self.hasActiveTransfers = hasActiveTransfers
        self.hasCompletedTransfers = hasCompletedTransfers
        self.hasFailedTransfers = hasFailedTransfers
    }

    public var hasAnyTransfers: Bool {
        hasActiveTransfers || hasCompletedTransfers || hasFailedTransfers
    }

    /// Empty-state label resolved against (hasAnyTransfers, selectedTab). When the
    /// screen has no transfers anywhere the tab bar is hidden, so the message is the
    /// global "No transfers" — otherwise it's specific to the visible tab.
    public var emptyStateLabel: String {
        guard hasAnyTransfers else {
            return Strings.Localizable.Transfers.EmptyState.noTransfers
        }
        switch selectedTab {
        case .active: return Strings.Localizable.Transfers.EmptyState.noActiveTransfers
        case .completed: return Strings.Localizable.Transfers.EmptyState.noCompletedTransfers
        case .failed: return Strings.Localizable.Transfers.EmptyState.noFailedTransfers
        }
    }

    public var isCurrentTabEmpty: Bool {
        switch selectedTab {
        case .active: !hasActiveTransfers
        case .completed: !hasCompletedTransfers
        case .failed: !hasFailedTransfers
        }
    }
}
