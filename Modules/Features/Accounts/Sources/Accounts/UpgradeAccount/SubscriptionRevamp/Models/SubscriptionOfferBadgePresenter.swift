import MEGADomain
import MEGAL10n

struct SubscriptionOfferBadgePresenter {
    private let priceUseCase: any SubscriptionPlanPriceUseCaseProtocol

    init(priceUseCase: any SubscriptionPlanPriceUseCaseProtocol = SubscriptionPlanPriceUseCase()) {
        self.priceUseCase = priceUseCase
    }

    func badge(for plan: PlanEntity) -> String? {
        guard let percentage = discountPercentage(for: plan) else { return nil }
        return badgeText(label: plan.mobileOffer?.label, percentage: percentage)
    }

    func discountPercentage(for plan: PlanEntity) -> Int? {
        priceUseCase.planPrice(for: plan).discountPercentage
    }

    private func badgeText(label: String?, percentage: Int) -> String {
        let discount = "\(percentage)%"
        if let label, !label.isEmpty {
            return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOfferLabel(label, discount)
        }
        return Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOffer(discount)
    }
}
