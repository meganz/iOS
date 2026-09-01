import Foundation
import MEGADomain
import MEGAL10n

/// Presents the billing-cycle picker: the available cycles, their titles, and the yearly saving text.
struct SubscriptionCycleViewModel {
    let plans: [PlanEntity]
    // Plans excluded from `savingPercentage`: the featured one is shown as the hero card,
    // the current one is not rendered at all.
    private let featuredPlan: PlanEntity?
    private let currentPlan: PlanEntity?
    private let priceUseCase: any SubscriptionPlanPriceUseCaseProtocol
    private let tracker: any UpgradePlansAnalyticsUseCaseProtocol

    init(
        plans: [PlanEntity],
        featuredPlan: PlanEntity? = nil,
        currentPlan: PlanEntity? = nil,
        priceUseCase: any SubscriptionPlanPriceUseCaseProtocol = SubscriptionPlanPriceUseCase(),
        tracker: any UpgradePlansAnalyticsUseCaseProtocol
    ) {
        self.plans = plans
        self.featuredPlan = featuredPlan
        self.currentPlan = currentPlan
        self.priceUseCase = priceUseCase
        self.tracker = tracker
    }
    
    func didSelectCycle(_ cycle: SubscriptionCycleEntity) {
        tracker.trackCycleToggle(cycle)
    }

    var options: [SubscriptionCycleEntity] {
        let available = Set(plans.map(\.subscriptionCycle))
        return [.monthly, .yearly].filter(available.contains)
    }

    func title(for cycle: SubscriptionCycleEntity) -> String {
        switch cycle {
        case .monthly: Strings.Localizable.monthly
        case .yearly: Strings.Localizable.yearly
        case .none: ""
        }
    }

    var savingText: String? {
        guard let percentage = savingPercentage, percentage > 0 else { return nil }
        return Strings.Localizable.SubscriptionPurchase.Revamp.Cycle.saving("\(percentage)%")
    }

    /// When any plan other than the featured one carries an offer, the saving reflects the offer
    /// with the highest discount; otherwise it falls back to the yearly-vs-monthly base saving.
    private var savingPercentage: Int? {
        maxOfferDiscountPercentage ?? maxYearlySavingPercentage
    }

    private var maxOfferDiscountPercentage: Int? {
        plans
            .filter { $0.subscriptionCycle == .yearly && $0 != featuredPlan && $0 != currentPlan }
            .compactMap { priceUseCase.planPrice(for: $0).discountPercentage }
            .max()
    }

    private var maxYearlySavingPercentage: Int? {
        let monthlyPriceByType = Dictionary(
            plans.filter { $0.subscriptionCycle == .monthly }.map { ($0.type, $0.price) },
            uniquingKeysWith: { first, _ in first }
        )
        let savings: [Int] = plans
            .filter { $0.subscriptionCycle == .yearly && $0 != currentPlan }
            .compactMap { yearly in
                guard let monthlyPrice = monthlyPriceByType[yearly.type], monthlyPrice > 0 else { return nil }
                let ratio = (yearly.price / 12) / monthlyPrice
                let percentage = NSDecimalNumber(decimal: (1 - ratio) * 100).rounding(accordingToBehavior: nil).intValue
                return percentage > 0 ? percentage : nil
            }
        return savings.max()
    }
}
