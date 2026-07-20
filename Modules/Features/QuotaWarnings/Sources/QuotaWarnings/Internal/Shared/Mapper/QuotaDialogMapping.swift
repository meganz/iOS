import MEGAAppPresentation
import MEGADomain
import MEGAL10n

/// Maps the domain result (`AccountDetailsEntity` + `RecommendedUpgradePlanEntity`) into the presentation
/// models the dialog renders. Storage and transfer each provide their own implementation (with severity
/// baked in); the shared recommended-card mapping lives here.
protocol QuotaDialogMapping {
    func header(accountDetails: AccountDetailsEntity) -> QuotaDialogHeader
    func currentPlan(accountDetails: AccountDetailsEntity) -> CurrentPlan
    func recommendedPlan(_ plan: RecommendedUpgradePlanEntity, accountDetails: AccountDetailsEntity) -> RecommendedPlan
}

extension QuotaDialogMapping {
    /// Builds the recommended-plan card model; callers supply the quota progress (storage- or transfer-based).
    func makeRecommendedPlan(_ plan: RecommendedUpgradePlanEntity, quotaProgress: QuotaProgress) -> RecommendedPlan {
        RecommendedPlan(
            name: plan.name,
            ribbonText: ribbonText(mobileOfferLabel: plan.mobileOfferLabel, price: plan.price),
            price: RecommendedPlanPriceMapper().map(plan.price),
            storageText: Strings.Localizable.SubscriptionPurchase.Plan.storage(plan.storage),
            transferText: Strings.Localizable.SubscriptionPurchase.Plan.transfer(plan.transfer),
            quotaProgress: quotaProgress
        )
    }

    func ribbonText(mobileOfferLabel: String?, price: SubscriptionPlanPrice) -> String {
        guard let percentage = price.discountPercentage, percentage > 0 else {
            return Strings.Localizable.QuotaWarning.RecommendedPlan.Tag.bestForYou
        }
        let discount = "\(percentage)%"
        if let campaign = mobileOfferLabel, !campaign.isEmpty {
            return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOfferLabel(campaign, discount)
        }
        return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOffer(discount)
    }
}
