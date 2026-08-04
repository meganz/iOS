import MEGADomain
import MEGAL10n

/// Maps a plan to its "buy on our website" button: whether the button shows, and its title.
///
/// Exists only when external purchase is available screen-wide, so holding one means
/// `shouldProvideExternalPurchase()` already passed.
struct ExternalPurchasePresenter: Sendable {
    /// Whether the low-emphasis "buy on our website" button should show for a plan.
    ///
    /// Combines the legacy `buyExternallyButtonTitle` gate: the plan must carry an API price and
    /// have no eligible offer.
    func isExternalPurchaseEnabled(for plan: PlanEntity) -> Bool {
        plan.apiPrice != nil && plan.applicableOffer == nil
    }

    /// The "buy on our website" button title for a plan, or `nil` when the plan is not eligible.
    func externalPurchaseTitle(for plan: PlanEntity) -> String? {
        guard isExternalPurchaseEnabled(for: plan) else { return nil }
        // [IOS-12354]: Handle actual discount value
        return Strings.Localizable.SubscriptionPurchase.Revamp.Button.BuyOnWebsite.saveUpTo("15%")
    }
}
