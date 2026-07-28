import MEGADomain
import MEGAL10n

struct SubscriptionOfferBadgePresenter {
    private let priceUseCase: any SubscriptionPlanPriceUseCaseProtocol

    init(priceUseCase: any SubscriptionPlanPriceUseCaseProtocol = SubscriptionPlanPriceUseCase()) {
        self.priceUseCase = priceUseCase
    }

    func badge(for plan: PlanEntity) -> String? {
        guard let percentage = priceUseCase.planPrice(for: plan).discountPercentage else { return nil }
        return badgeText(label: plan.mobileOffer?.label, percentage: percentage)
    }

    private func badgeText(label: String?, percentage: Int) -> String {
        let discount = "\(percentage)%"
        if let label, !label.isEmpty {
            return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOfferLabel(label, discount)
        }
        return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOffer(discount)
    }
}
