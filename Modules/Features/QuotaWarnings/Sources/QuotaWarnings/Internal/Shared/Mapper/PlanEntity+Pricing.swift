import Foundation
import MEGADomain
import MEGAL10n
import MEGAUIComponent

extension PlanEntity {
    var ribbonText: String {
        // IOS-12210
        return "Best for you"
    }

    var price: PlanPrice {
        // Discount price will handled in separate ticket
        if subscriptionCycle == .yearly {
            return .yearly(
                price: Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.localCurrencyPerMonth(formattedMonthlyPriceForYearlyPlan ?? formattedPrice),
                billing: Strings.Localizable.SubscriptionPurchase.Plan.billedYearly(formattedPriceForYearlyPlan ?? formattedPrice)
            )
        }

        return .monthly(
            price: Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.localCurrencyPerMonth(formattedPrice)
        )
    }
}
