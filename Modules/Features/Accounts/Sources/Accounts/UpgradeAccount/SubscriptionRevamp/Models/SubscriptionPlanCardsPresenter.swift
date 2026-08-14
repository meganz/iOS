import MEGADomain
import MEGAL10n
import MEGAUIComponent

/// Builds the standard plan cards for a billing cycle.
/// In the single-offer case the featured plan is excluded (shown as the hero card instead).
struct SubscriptionPlanCardsPresenter {
    /// The page the cards are built for. Each singles out one plan, in mutually exclusive ways:
    /// the promo page pulls its featured plan out into the hero card, the standard page tags a tier
    /// in place. Modelled as enum so the two can never be set together.
    enum PageType {
        case standard(recommendedPlanType: AccountTypeEntity?)
        case promo(featuredPlan: PlanEntity?)
    }

    /// All available plans
    let plans: [PlanEntity]
    let pageType: PageType
    let displayName: @Sendable (AccountTypeEntity) -> String
    /// Maps the "buy on our website" button; `nil` when the capability is unavailable (non-US storefront or flag off).
    let externalPurchase: ExternalPurchasePresenter?

    func cards(for cycle: SubscriptionCycleEntity) -> [SubscriptionPlanCardModel] {
        let resolver = SubscriptionPlanPriceResolver()
        let offerBadgePresenter = SubscriptionOfferBadgePresenter()
        return plans
            .filter { $0.subscriptionCycle == cycle && $0 != featuredPlan }
            .map { plan in
                let ribbon: SubscriptionPlanCardModel.Ribbon? = switch pageType {
                case .standard(let recommendedPlanType): plan.type == recommendedPlanType ? .recommended : nil
                case .promo: offerBadgePresenter.badge(for: plan).map { .offer($0) }
                }

                return SubscriptionPlanCardModel(
                    productIdentifier: plan.productIdentifier,
                    title: displayName(plan.type),
                    price: resolver.planPrice(for: plan),
                    storage: Strings.Localizable.SubscriptionPurchase.Plan.storage(plan.storage),
                    transfer: Strings.Localizable.SubscriptionPurchase.Plan.transfer(plan.transfer),
                    ribbon: ribbon,
                    isPrimaryAction: ribbon == .recommended,
                    externalPurchaseTitle: externalPurchase?.externalPurchaseTitle(for: plan)
                )
            }
    }

    private var featuredPlan: PlanEntity? {
        switch pageType {
        case .promo(let featuredPlan): featuredPlan
        case .standard: nil
        }
    }
}
