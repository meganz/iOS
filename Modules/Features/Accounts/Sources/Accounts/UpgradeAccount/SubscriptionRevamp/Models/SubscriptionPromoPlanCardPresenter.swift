import MEGADomain
import MEGAL10n
import MEGAUIComponent

/// Builds the featured (hero) promo plan card from the single discounted plan.
struct SubscriptionPromoPlanCardPresenter {
    let plan: PlanEntity
    let displayName: @Sendable (AccountTypeEntity) -> String

    var cardModel: SubscriptionRevampPromoPlanCardModel {
        let name = displayName(plan.type)
        return SubscriptionRevampPromoPlanCardModel(
            ribbonText: SubscriptionOfferBadgePresenter().badge(for: plan) ?? "",
            title: name,
            price: SubscriptionPlanPriceResolver().planPrice(for: plan),
            storage: plan.storage,
            transfer: plan.transfer,
            buttonTitle: Strings.Localizable.SubscriptionPurchase.Button.getPlan(name)
        )
    }
}
