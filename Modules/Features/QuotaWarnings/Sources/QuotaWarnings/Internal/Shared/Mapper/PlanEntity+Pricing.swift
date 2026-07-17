import MEGADomain
import MEGAL10n

extension PlanEntity {
    func ribbonText(for price: SubscriptionPlanPrice) -> String {
        guard let percentage = price.discountPercentage, percentage > 0 else {
            // IOS-12210
            return "Best for you"
        }
        let discount = "\(percentage)%"
        if let campaign = mobileOfferLabel, !campaign.isEmpty {
            return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOfferLabel(campaign, discount)
        }
        return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOffer(discount)
    }
}
