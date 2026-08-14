import Foundation
import MEGADomain

public protocol PromotedPlanUseCaseProtocol: Sendable {
    /// The cheapest upgrade whose offer may be advertised, or `nil` when there is none. Ties go to the yearly cycle.
    /// - Parameter checksForExpiry: when `true`, an offer is also rejected once its expiry date passes. Offers without one never lapse.
    func fetchPromotedPlan(checksForExpiry: Bool) async throws -> PromotedPlanEntity?
}

public struct PromotedPlanUseCase: PromotedPlanUseCaseProtocol {
    private let pricingRequester: any PricingRequesting
    private let fetchUseCase: any RevampUpgradePlansUseCaseProtocol

    public init(
        pricingRequester: some PricingRequesting,
        fetchUseCase: some RevampUpgradePlansUseCaseProtocol
    ) {
        self.pricingRequester = pricingRequester
        self.fetchUseCase = fetchUseCase
    }

    public func fetchPromotedPlan(checksForExpiry: Bool) async throws -> PromotedPlanEntity? {
        // Offers may become invalid for various reasons, such as expiring, or no longer being exposed once the user converts.
        // Reload the products so an offer is advertised on what the API says now, not on what it said previously, such as at login.
        // The API guarantees that once a user upgrades during the campaign, it will stop exposing offers for that user in MEGAPricing.
        // Therefore, we should refresh MEGAPricing regularly to ensure the offers remain up to date.
        try await pricingRequester.refreshPricing()
        async let accountDetailsResult = fetchUseCase.currentAccountDetails()
        async let plansResult = fetchUseCase.plans()
        let accountDetails = try await accountDetailsResult
        let plans = await plansResult

        guard let plan = cheapestOfferedPlan(in: plans, accountDetails: accountDetails),
              let mobileOffer = plan.mobileOffer,
              mobileOffer.isAdvertisable,
              !(checksForExpiry && mobileOffer.hasExpired) else { return nil }

        return PromotedPlanEntity(plan: plan, offer: mobileOffer)
    }

    private func cheapestOfferedPlan(
        in plans: [PlanEntity],
        accountDetails: AccountDetailsEntity
    ) -> PlanEntity? {
        upgradeCandidates(in: plans, accountDetails: accountDetails)
            .compactMap { plan in
                plan.applicableOffer.map { (plan: plan, offer: $0) }
            }
            .min(by: isCheaperPromotion)?
            .plan
    }

    /// Filter for the candidates for promotion: A candidate is a plan that has higher tier and not the current plan user owns
    /// In practice promotions are only apply to free users, but we still need to filter candidate plans just in case.
    private func upgradeCandidates(
        in plans: [PlanEntity],
        accountDetails: AccountDetailsEntity
    ) -> [PlanEntity] {
        let currentStorageLimit = plans.first { $0.type == accountDetails.proLevel }?.storageLimit ?? 0
        return plans.filter { !$0.isCurrentPlan(for: accountDetails) && $0.storageLimit >= currentStorageLimit }
    }

    private func isCheaperPromotion(
        _ lhs: (plan: PlanEntity, offer: SubscriptionOfferEntity),
        _ rhs: (plan: PlanEntity, offer: SubscriptionOfferEntity)
    ) -> Bool {
        let lhsPricePerMonth = lhs.offer.billingSchedule.pricePerMonth
        let rhsPricePerMonth = rhs.offer.billingSchedule.pricePerMonth
        guard lhsPricePerMonth == rhsPricePerMonth else { return lhsPricePerMonth < rhsPricePerMonth }
        // In case there's a tie in per-month price, we recommend the yearly plan
        return lhs.plan.subscriptionCycle == .yearly && rhs.plan.subscriptionCycle != .yearly
    }
}

private extension MobileOfferEntity {
    var hasExpired: Bool {
        guard let expiryDate = expiryDate else { return false }
        return expiryDate <= Date()
    }
}
