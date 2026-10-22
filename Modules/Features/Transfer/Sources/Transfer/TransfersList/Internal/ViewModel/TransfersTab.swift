import MEGAL10n

/// The three tabs that segment the Transfers list.
///
/// Order in `allCases` matches the on-screen left-to-right order:
/// `active` → `completed` → `failed`.
public enum TransfersTab: CaseIterable, Sendable, Identifiable {
    case active
    case completed
    case failed

    public var id: Self { self }

    var title: String {
        switch self {
        case .active: Strings.Localizable.Transfers.Tab.active
        case .completed: Strings.Localizable.Transfers.Tab.completed
        case .failed: Strings.Localizable.Transfers.Tab.failed
        }
    }

    /// Whether the tab offers a search bar. Active has none, so its list ignores any query.
    var isSearchable: Bool {
        self != .active
    }

    /// Whether the tab lists its rows in transfer-queue order. Only in-flight
    /// transfers are queued, so only Active.
    var isQueueOrdered: Bool {
        self == .active
    }

    var emptyStateTitle: String {
        switch self {
        case .active: Strings.Localizable.Transfers.EmptyState.noActiveTransfers
        case .completed: Strings.Localizable.Transfers.EmptyState.noCompletedTransfers
        case .failed: Strings.Localizable.Transfers.EmptyState.noFailedTransfers
        }
    }
}
