import Foundation
import MEGASwift

public protocol RecommendedUpgradePlanUseCaseProtocol: Sendable {
    /// Picks the plan to recommend as an upgrade for the given account, from the provided plans
    /// Returns `nil` when there is no such plan
    func recommend(
        for accountDetails: AccountDetailsEntity,
        from plans: [PlanEntity]
    ) -> RecommendedUpgradePlanEntity?
}

/// Recommendation rules
/// Recommends the cheapest plan that resolves the over-quota state:
/// - **Target billing cycle:** free → `.yearly`; paid → the account's current cycle (a paid `.none` cycle
///   falls back to `.yearly`).
/// - **Eligible plans:** those in the target cycle whose `storageLimit` **and** `transferLimit` are strictly
///   greater than the account's current **allowance**: `max(storageUsed, storageMax)` / `max(transferUsed,
///   transferMax)`.
/// - **Winner:** the eligible plan with the lowest **effective per-month** price (tie breaker is `storageLimit`).
///   The per-month price folds in any introductory discount, so a discounted higher-tier plan wins whenever
///   its per-month is the cheapest. A free-trial offer (per-month 0) always wins.
/// - No eligible plan (nothing in the target cycle has enough storage/transfer headroom) → `nil`.
public struct RecommendedUpgradePlanUseCase: RecommendedUpgradePlanUseCaseProtocol {
    private let subscriptionPlanPriceUseCase: any SubscriptionPlanPriceUseCaseProtocol

    public init(subscriptionPlanPriceUseCase: some SubscriptionPlanPriceUseCaseProtocol) {
        self.subscriptionPlanPriceUseCase = subscriptionPlanPriceUseCase
    }

    public func recommend(
        for accountDetails: AccountDetailsEntity,
        from plans: [PlanEntity]
    ) -> RecommendedUpgradePlanEntity? {
        let eligiblePlans = plansEligibleForRecommendation(accountDetails: accountDetails, plans: plans)
        
        guard let bestPlan = eligiblePlans.min(by: {
            (effectivePricePerMonth($0), $0.storageLimit) < (effectivePricePerMonth($1), $1.storageLimit)
        }) else { return nil }
        
        return RecommendedUpgradePlanEntity(
            name: bestPlan.name,
            storage: bestPlan.storage,
            storageLimit: bestPlan.storageLimit,
            transfer: bestPlan.transfer,
            transferLimit: bestPlan.transferLimit,
            mobileOfferLabel: bestPlan.mobileOfferLabel,
            price: subscriptionPlanPriceUseCase.planPrice(for: bestPlan)
        )
    }
    
    private func plansEligibleForRecommendation(accountDetails: AccountDetailsEntity, plans: [PlanEntity]) -> [PlanEntity] {
        let recommendedCycle: SubscriptionCycleEntity = if accountDetails.isFree {
            .yearly // Always recommend .yearly for free user
        } else {
            switch accountDetails.subscriptionCycle { // Recommend the same cycle with current subscription cycle. Otherwise, recommend .yearly
            case .none: .yearly
            case .monthly: .monthly
            case .yearly: .yearly
            }
        }
        
        // In case of almostFull, the usage is still below the current plan's limit.
        // Simply compare against the usage would keep the current plan eligible for recommendation.
        // Hence, using `max(usage, limit)` to exclude the current from eligible plans for recommendation.
        let requiredStorage = max(accountDetails.storageUsed, accountDetails.storageMax)
        let requiredTransfer = max(accountDetails.transferUsed, accountDetails.transferMax)

        let isEligiblePlan: (PlanEntity) -> Bool = { plan in
            let sameCycle = plan.subscriptionCycle == recommendedCycle
            let hasMoreStorage = plan.storageLimit.gigabytesToBytes() > requiredStorage
            let hasMoreTransfer = plan.transferLimit.gigabytesToBytes() > requiredTransfer
            return sameCycle && hasMoreStorage && hasMoreTransfer
        }

        return plans.filter(isEligiblePlan)
    }
    
    private func effectivePricePerMonth(_ plan: PlanEntity) -> Decimal {
        if let offer = plan.introductoryOffer { return offer.billingSchedule.pricePerMonth }
        return plan.subscriptionCycle == .yearly ? plan.price / 12 : plan.price
    }
}
