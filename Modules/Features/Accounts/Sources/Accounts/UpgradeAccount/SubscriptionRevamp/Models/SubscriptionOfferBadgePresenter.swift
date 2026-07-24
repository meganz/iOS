import MEGADomain
import MEGAL10n

/// Computes the discount badge (ribbon) text for a plan.
///
/// Introductory offers take priority over promotional offers on the same plan. Introductory badges
/// derive their percentage from `SubscriptionPlanPriceUseCase`; promotional badges use
/// `mobileOffer.label` + `discountPercentage`.
struct SubscriptionOfferBadgePresenter {
    private let priceUseCase: any SubscriptionPlanPriceUseCaseProtocol

    init(priceUseCase: any SubscriptionPlanPriceUseCaseProtocol = SubscriptionPlanPriceUseCase()) {
        self.priceUseCase = priceUseCase
    }

    func badge(for plan: PlanEntity) -> String? {
        if plan.introductoryOffer != nil {
            guard let percentage = priceUseCase.planPrice(for: plan).discountPercentage else { return nil }
            return badgeText(label: plan.mobileOffer?.label, percentage: percentage)
        }
        if plan.hasValidPromotionalOffer, let offer = plan.mobileOffer {
            // For discount percentage of promo offers, we rely on the value returned from API instead not
            // computing from the promo offer object from StoreKit
            return badgeText(label: offer.label, percentage: offer.discountPercentage)
        }
        return nil
    }

    private func badgeText(label: String?, percentage: Int) -> String {
        let discount = "\(percentage)%"
        if let label, !label.isEmpty {
            return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOfferLabel(label, discount)
        }
        return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOffer(discount)
    }
}
