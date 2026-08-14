import MEGADomain
import MEGAPreference

/// Where one account's last app-open presentation of one promotional campaign is stored.
///
/// The account handle and the campaign id are both part of the key, so two accounts on the same device gate each
/// other's dialog independently, and a showing left behind by a finished campaign cannot gate the next one.
struct PromoDialogReshowKey: PreferenceKeyProtocol {
    let accountHandle: HandleEntity
    let campaignId: UInt64

    /// What every stored showing for `accountHandle` starts with, so QA can find them all without having to know
    /// which campaigns have run on this device.
    static func shownDatePrefix(accountHandle: HandleEntity) -> String {
        "accounts.promoDialog.ShownDate-\(accountHandle)-"
    }

    var rawValue: String {
        Self.shownDatePrefix(accountHandle: accountHandle) + String(campaignId)
    }
}
