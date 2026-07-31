import MEGADomain
import MEGAUIComponent

/// Builds the standard plan cards for a billing cycle.
/// In the single-offer case the featured plan is excluded (shown as the hero card instead).
struct SubscriptionPlanCardsPresenter {
    /// All available plans
    let plans: [PlanEntity]
    /// The discounted plan shown as the hero card, to be excluded from `func card()`
    let featuredPlan: PlanEntity?
    let displayName: @Sendable (AccountTypeEntity) -> String

    func cards(for cycle: SubscriptionCycleEntity) -> [SubscriptionPlanCardModel] {
        let resolver = SubscriptionPlanPriceResolver()
        let badgePresenter = SubscriptionOfferBadgePresenter()
        return plans
            .filter { $0.subscriptionCycle == cycle && $0 != featuredPlan }
            .map { plan in
                SubscriptionPlanCardModel(
                    productIdentifier: plan.productIdentifier,
                    title: displayName(plan.type),
                    price: resolver.planPrice(for: plan),
                    storage: plan.storage,
                    transfer: plan.transfer,
                    ribbonText: badgePresenter.badge(for: plan)
                )
            }
    }
}
