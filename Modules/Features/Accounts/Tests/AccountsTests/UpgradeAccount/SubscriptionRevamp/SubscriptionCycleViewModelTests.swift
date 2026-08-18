@testable import Accounts
import MEGADomain
import MEGADomainMock
import MEGAL10n
import Testing

@Suite("SubscriptionCycleViewModel - yearly saving text")
struct SubscriptionCycleViewModelTests {

    private func discountYearlyPrice(_ percentage: Int) -> SubscriptionPlanPrice {
        .discountYearly(.init(
            yearly: .init(price: 0, currency: ""),
            offer: .init(
                originalPrice: 0,
                discountPercentage: percentage,
                schedule: .prepaid(price: 0, period: .init(unit: .month, value: 12))
            )
        ))
    }

    private func makeSUT(
        plans: [PlanEntity],
        planPrice: SubscriptionPlanPrice,
        tracker: MockUpgradePlansAnalyticsUseCase = MockUpgradePlansAnalyticsUseCase()
    ) -> SubscriptionCycleViewModel {
        SubscriptionCycleViewModel(
            plans: plans,
            priceUseCase: MockSubscriptionPlanPriceUseCase(planPrice: planPrice),
            tracker: tracker
        )
    }

    @Test("Selecting a cycle reports it")
    func didSelectCycle_reportsTheCycle() {
        let tracker = MockUpgradePlansAnalyticsUseCase()
        let sut = makeSUT(
            plans: monthlyAndYearlyPlans,
            planPrice: .yearly(.init(price: 0, currency: "")),
            tracker: tracker
        )

        sut.didSelectCycle(.monthly)
        sut.didSelectCycle(.yearly)

        #expect(tracker.invocations == [.cycleToggle(.monthly), .cycleToggle(.yearly)])
    }

    /// Monthly 10 vs yearly 96 => base yearly-vs-monthly saving of 20%.
    private var monthlyAndYearlyPlans: [PlanEntity] {
        [
            PlanEntity(type: .proI, subscriptionCycle: .monthly, price: 10),
            PlanEntity(type: .proI, subscriptionCycle: .yearly, price: 96)
        ]
    }

    @Test("An offer discount takes priority over the base yearly-vs-monthly saving")
    func offerDiscountTakesPriorityOverBaseSaving() {
        let sut = makeSUT(plans: monthlyAndYearlyPlans, planPrice: discountYearlyPrice(30))
        #expect(sut.savingText == Strings.Localizable.SubscriptionPurchase.Revamp.Cycle.saving("30%"))
    }

    @Test("With no offer, the saving falls back to the base yearly-vs-monthly percentage")
    func fallsBackToBaseSavingWithoutOffer() {
        let sut = makeSUT(plans: monthlyAndYearlyPlans, planPrice: .yearly(.init(price: 0, currency: "")))
        #expect(sut.savingText == Strings.Localizable.SubscriptionPurchase.Revamp.Cycle.saving("20%"))
    }

    @Test("No yearly plan yields no saving text")
    func noYearlyPlanYieldsNoSavingText() {
        let sut = makeSUT(
            plans: [PlanEntity(type: .proI, subscriptionCycle: .monthly, price: 10)],
            planPrice: .yearly(.init(price: 0, currency: ""))
        )
        #expect(sut.savingText == nil)
    }
}
