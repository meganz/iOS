#if DEBUG || QA_CONFIG
import MEGADomain

extension RecommendedUpgradePlanEntity {
    /// Builds a recommended-plan entity straight from a `PlanEntity`, for QA/preview doubles only.
    /// Production selection + pricing lives in `RecommendedUpgradePlanUseCase`.
    init(plan: PlanEntity) {
        self.init(
            productIdentifier: plan.productIdentifier,
            name: plan.name,
            storage: plan.storage,
            storageLimit: plan.storageLimit,
            transfer: plan.transfer,
            transferLimit: plan.transferLimit,
            mobileOfferLabel: plan.mobileOfferLabel,
            price: SubscriptionPlanPriceUseCase().planPrice(for: plan)
        )
    }
}
#endif
