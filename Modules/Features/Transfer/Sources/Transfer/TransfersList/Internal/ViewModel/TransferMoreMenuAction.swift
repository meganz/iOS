import MEGAL10n

/// An action presented in the top-bar More menu (the ellipsis button) on the Transfers list.
///
/// The set shown depends on the selected tab (see `TransfersListViewModel.menuActions`).
/// This type only describes the menu item; its title comes from `MEGAL10n`, while the
/// icon and tap handler are supplied by the view that renders the menu.
enum TransferMoreMenuAction: Identifiable {
    case select
    case cancelAll
    case clearAll
    case retryAll

    var id: Self { self }

    var title: String {
        switch self {
        case .select: Strings.Localizable.select
        case .cancelAll: Strings.Localizable.Transfers.Action.cancelAllTransfers
        case .clearAll: Strings.Localizable.Transfers.Action.clearAllTransfers
        case .retryAll: Strings.Localizable.Transfers.Action.retryAllTransfers
        }
    }
}
