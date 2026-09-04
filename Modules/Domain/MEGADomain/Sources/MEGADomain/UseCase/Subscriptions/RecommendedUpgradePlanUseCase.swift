import Foundation
import MEGASwift

public enum RecommendedUpgradePlanError: Error, Sendable {
    case noPlanToRecommend
}

public enum RecommendedPlanCycleTarget: Sendable {
    case fromCurrentUser
    case specific(cycle: SubscriptionCycleEntity)
}

public protocol RecommendedUpgradePlanUseCaseProtocol: Sendable {
    /// Picks the plan to recommend as an upgrade for the given account, from the provided plans, within the
    /// cycle `cycleTarget` names - the account's own (`.fromCurrentUser`) or one the caller picked
    /// (`.specific(cycle:)`)
    /// Returns `nil` when there is no such plan
    func recommend(
        for accountDetails: AccountDetailsEntity,
        from plans: [PlanEntity],
        cycleTarget: RecommendedPlanCycleTarget
    ) -> RecommendedUpgradePlanEntity?

    /// Picks the plan to recommend to someone who has no account yet: the cheapest yearly plan.
    ///
    /// Non-optional where `recommend(for:from:cycleTarget:)` returns `nil`, because "nothing to recommend" means
    /// something different here: there should be a plan for a brand-new account, so the absence of an answer says the
    /// catalog is unusable, not that the user has run out of options.
    /// - Throws: `RecommendedUpgradePlanError.noPlanToRecommend` when the catalog holds no yearly plan.
    func recommendForNewAccount(from plans: [PlanEntity]) throws -> RecommendedUpgradePlanEntity
}

/// Recommendation rules
/// Recommends the cheapest plan that resolves the over-quota state:
/// - **Target billing cycle:** `.specific(cycle:)` uses that cycle as-is; `.fromCurrentUser` derives it -
///   free → `.yearly`; paid → the account's current cycle (a paid `.none` cycle falls back to `.yearly`).
/// - **Eligible plans:** those in the target cycle whose `storageLimit` **and** `transferLimit` are strictly
///   greater than the account's current **allowance**: `max(storageUsed, storageMax)` / `max(transferUsed,
///   transferMax)`.
/// - **Winner:** the eligible plan with the lowest **effective per-month** price (tie breaker is `storageLimit`).
///   The per-month price folds in any introductory discount, so a discounted higher-tier plan wins whenever
///   its per-month is the cheapest. A free-trial offer (per-month 0) always wins.
/// - No eligible plan (nothing in the target cycle has enough storage/transfer headroom) → `nil`.
///
/// The eligibility and price rules are identical for both cycle targets; only the cycle they draw from differs.
///
/// For signed out user (`recommendForNewAccount(from:)`) only the cycle and the price rules apply.
public struct RecommendedUpgradePlanUseCase: RecommendedUpgradePlanUseCaseProtocol {
    private let subscriptionPlanPriceUseCase: any SubscriptionPlanPriceUseCaseProtocol

    public init(subscriptionPlanPriceUseCase: some SubscriptionPlanPriceUseCaseProtocol) {
        self.subscriptionPlanPriceUseCase = subscriptionPlanPriceUseCase
    }

    public func recommend(
        for accountDetails: AccountDetailsEntity,
        from plans: [PlanEntity],
        cycleTarget: RecommendedPlanCycleTarget
    ) -> RecommendedUpgradePlanEntity? {
        let cycle = resolvedCycle(for: accountDetails, cycleTarget: cycleTarget)
        let eligiblePlans = plansEligibleForRecommendation(accountDetails: accountDetails, plans: plans, cycle: cycle)

        guard let bestPlan = eligiblePlans.min(by: isCheaperPlan) else { return nil }

        return recommendedUpgradePlanEntity(from: bestPlan)
    }

    public func recommendForNewAccount(from plans: [PlanEntity]) throws -> RecommendedUpgradePlanEntity {
        let bestPlan = plans
            .filter { $0.subscriptionCycle == .yearly }
            .min(by: isCheaperPlan)

        guard let bestPlan else {
            throw RecommendedUpgradePlanError.noPlanToRecommend
        }

        return recommendedUpgradePlanEntity(from: bestPlan)
    }

    private func resolvedCycle(
        for accountDetails: AccountDetailsEntity,
        cycleTarget: RecommendedPlanCycleTarget
    ) -> SubscriptionCycleEntity {
        switch cycleTarget {
        case .specific(let cycle): cycle
        case .fromCurrentUser: cycleFromCurrentUser(for: accountDetails)
        }
    }

    private func cycleFromCurrentUser(for accountDetails: AccountDetailsEntity) -> SubscriptionCycleEntity {
        if accountDetails.isFree {
            .yearly // Always recommend .yearly for free user
        } else {
            switch accountDetails.subscriptionCycle { // Recommend the same cycle with current subscription cycle. Otherwise, recommend .yearly
            case .none: .yearly
            case .monthly: .monthly
            case .yearly: .yearly
            }
        }
    }

    private func plansEligibleForRecommendation(
        accountDetails: AccountDetailsEntity,
        plans: [PlanEntity],
        cycle: SubscriptionCycleEntity
    ) -> [PlanEntity] {
        // In case of almostFull, the usage is still below the current plan's limit.
        // Simply compare against the usage would keep the current plan eligible for recommendation.
        // Hence, using `max(usage, limit)` to exclude the current from eligible plans for recommendation.
        let requiredStorage = max(accountDetails.storageUsed, accountDetails.storageMax)
        let requiredTransfer = max(accountDetails.transferUsed, accountDetails.transferMax)

        let isEligiblePlan: (PlanEntity) -> Bool = { plan in
            let sameCycle = plan.subscriptionCycle == cycle
            let hasMoreStorage = plan.storageLimit.gigabytesToBytes() > requiredStorage
            let hasMoreTransfer = plan.transferLimit.gigabytesToBytes() > requiredTransfer
            return sameCycle && hasMoreStorage && hasMoreTransfer
        }

        return plans.filter(isEligiblePlan)
    }
    
    private func effectivePricePerMonth(_ plan: PlanEntity) -> Decimal {
        if let offer = plan.applicableOffer { return offer.billingSchedule.pricePerMonth }
        return plan.subscriptionCycle == .yearly ? plan.price / 12 : plan.price
    }

    private func isCheaperPlan(_ lhs: PlanEntity, _ rhs: PlanEntity) -> Bool {
        (effectivePricePerMonth(lhs), lhs.storageLimit) < (effectivePricePerMonth(rhs), rhs.storageLimit)
    }

    private func recommendedUpgradePlanEntity(from plan: PlanEntity) -> RecommendedUpgradePlanEntity {
        RecommendedUpgradePlanEntity(
            productIdentifier: plan.productIdentifier,
            name: plan.name,
            storage: plan.storage,
            storageLimit: plan.storageLimit,
            transfer: plan.transfer,
            transferLimit: plan.transferLimit,
            mobileOfferLabel: plan.mobileOfferLabel,
            price: subscriptionPlanPriceUseCase.planPrice(for: plan)
        )
    }
}

/// Convenience for the common case: recommend within the cycle the account is already on.
public extension RecommendedUpgradePlanUseCaseProtocol {
    func recommend(
        for accountDetails: AccountDetailsEntity,
        from plans: [PlanEntity],
    ) -> RecommendedUpgradePlanEntity? {
        recommend(for: accountDetails, from: plans, cycleTarget: .fromCurrentUser)
    }
}
