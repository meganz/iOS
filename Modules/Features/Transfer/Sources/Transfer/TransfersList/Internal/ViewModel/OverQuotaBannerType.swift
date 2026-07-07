import MEGAL10n
import MEGAUIComponent

/// The over-quota banner shown above the Transfers list. A single banner is shown at a
/// time: when both quotas are exhausted the combined `.both` variant replaces the
/// individual ones (no stacking).
enum OverQuotaBannerType: Equatable {
    /// Transfer (bandwidth) quota exhausted. Yellow, dismissible.
    case transfer
    /// Storage quota exhausted. Pink, not dismissible (the state is too important to hide).
    case storage
    /// Both quotas exhausted. Yellow, dismissible.
    case both

    var title: String {
        switch self {
        case .transfer: Strings.Localizable.Transfers.OverQuotaBanner.Transfer.title
        case .storage: Strings.Localizable.Transfers.OverQuotaBanner.Storage.title
        case .both: Strings.Localizable.Transfers.OverQuotaBanner.Both.title
        }
    }

    var actionTitle: String {
        Strings.Localizable.Account.Storage.Banner.FullStorageOverQuotaBanner.button
    }

    /// Only the storage banner is non-dismissible; the transfer and combined variants
    /// carry a dismiss control.
    var showsDismiss: Bool {
        switch self {
        case .transfer, .both: true
        case .storage: false
        }
    }

    var bannerState: MEGABannerState {
        switch self {
        case .transfer, .both: .warning
        case .storage: .error
        }
    }
}
