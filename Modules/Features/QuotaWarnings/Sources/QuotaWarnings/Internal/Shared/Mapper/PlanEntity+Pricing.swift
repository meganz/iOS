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
        switch subscriptionCycle {
        case .monthly:
            PlanPrice.monthly(
                PlanPriceModel.Monthly(
                    pricePerMonth: Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.localCurrencyPerMonth(formattedPrice)
                )
            )
        case .yearly:
            PlanPrice.yearly(
                PlanPriceModel.Yearly(
                    pricePerMonth: Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.localCurrencyPerMonth(formattedMonthlyPriceForYearlyPlan ?? formattedPrice),
                    billingCaption: Strings.Localizable.SubscriptionPurchase.Plan.billedYearly(formattedPriceForYearlyPlan ?? formattedPrice)
                )
            )
        case .none:
            PlanPrice.monthly(
                PlanPriceModel.Monthly(
                    pricePerMonth: Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.localCurrencyPerMonth(formattedPrice)
                )
            )
        }
    }
}
