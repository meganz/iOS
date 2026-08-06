import MEGAL10n

/// What a confirmed cancel applies to.
///
/// Cancel is the only transfer action that prompts — clear and retry, all or
/// selected, run immediately
enum CancelConfirmation: Identifiable {
    /// Every ongoing transfer (More menu → Cancel all).
    case all
    /// The rows ticked in select mode on the Active tab.
    case selected

    var id: Self { self }

    var title: String { Strings.Localizable.Transfers.Confirmation.CancelAll.title }

    var message: String? {
        switch self {
        case .all: nil
        case .selected: Strings.Localizable.Transfers.Confirmation.CancelSelected.message
        }
    }

    /// The confirm button.
    var confirmTitle: String {
        switch self {
        case .all: Strings.Localizable.Transfers.Confirmation.CancelAll.confirm
        case .selected: Strings.Localizable.continue
        }
    }

    /// Only Cancel all is styled destructively. 
    var isConfirmDestructive: Bool {
        switch self {
        case .all: true
        case .selected: false
        }
    }
}
