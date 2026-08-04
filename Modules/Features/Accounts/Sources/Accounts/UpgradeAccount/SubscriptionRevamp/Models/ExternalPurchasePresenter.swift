import Foundation
import MEGADomain
import MEGAL10n

/// Maps a plan to its "buy on our website" button: whether the button shows, and its title.
///
/// Exists only when external purchase is available screen-wide, so holding one means
/// `shouldProvideExternalPurchase()` already passed.
struct ExternalPurchasePresenter: Sendable {
    /// Advertised when the plan's two prices cannot be compared, matching the legacy screen.
    private static let fallbackSavingPercentage = 15

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
        return Strings.Localizable.SubscriptionPurchase.Revamp.Button.BuyOnWebsite.saveUpTo("\(savingPercentage(for: plan))%")
    }

    /// How much cheaper the website is than the App Store for a plan, as a whole percentage.
    ///
    /// The two prices are only comparable in the same currency, so a plan priced in different currencies
    /// falls back to the advertised saving, as the legacy screen does.
    private func savingPercentage(for plan: PlanEntity) -> Int {
        let appStorePrice = plan.appStorePrice
        guard let apiPrice = plan.apiPrice,
              apiPrice.currency == appStorePrice.currency,
              apiPrice.price < appStorePrice.price,
              appStorePrice.price > 0
        else { return Self.fallbackSavingPercentage }

        let saving = ((appStorePrice.price - apiPrice.price) / appStorePrice.price) * 100
        return NSDecimalNumber(decimal: saving).rounding(accordingToBehavior: nil).intValue
    }
}
