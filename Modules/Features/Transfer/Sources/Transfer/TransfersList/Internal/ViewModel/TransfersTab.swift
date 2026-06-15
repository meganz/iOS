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
}
