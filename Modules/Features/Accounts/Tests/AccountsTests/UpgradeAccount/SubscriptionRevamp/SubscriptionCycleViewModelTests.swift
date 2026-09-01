@testable import Accounts
import Foundation
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
        featuredPlan: PlanEntity? = nil,
        currentPlan: PlanEntity? = nil,
        planPrice: SubscriptionPlanPrice,
        tracker: MockUpgradePlansAnalyticsUseCase = MockUpgradePlansAnalyticsUseCase()
    ) -> SubscriptionCycleViewModel {
        SubscriptionCycleViewModel(
            plans: plans,
            featuredPlan: featuredPlan,
            currentPlan: currentPlan,
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

    /// A yearly plan discounted by a 1-year pay-up-front intro offer, priced through the real
    /// `SubscriptionPlanPriceUseCase` so each plan can carry its own percentage.
    private func discountedYearlyPlan(_ type: AccountTypeEntity, price: Decimal, introPrice: Decimal) -> PlanEntity {
        PlanEntity(
            type: type,
            subscriptionCycle: .yearly,
            price: price,
            introductoryOffer: SubscriptionOfferEntity(
                price: introPrice,
                period: .init(unit: .year, value: 1),
                periodCount: 1,
                paymentMode: .payUpFront
            )
        )
    }

    @Test("Only the featured plan's offer is excluded; another plan's offer still counts")
    func featuredPlanOfferIsExcludedButOthersStillCount() {
        let featured = discountedYearlyPlan(.proI, price: 100, introPrice: 20)
        let sut = SubscriptionCycleViewModel(
            plans: [featured, discountedYearlyPlan(.proII, price: 100, introPrice: 60)],
            featuredPlan: featured,
            tracker: MockUpgradePlansAnalyticsUseCase()
        )
        #expect(sut.savingText == Strings.Localizable.SubscriptionPurchase.Revamp.Cycle.saving("40%"))
    }

    @Test("With the featured plan carrying the only offer, the saving falls back to the base percentage")
    func fallsBackToBaseSavingWhenFeaturedPlanCarriesTheOnlyOffer() {
        let sut = makeSUT(
            plans: monthlyAndYearlyPlans,
            featuredPlan: PlanEntity(type: .proI, subscriptionCycle: .yearly, price: 96),
            planPrice: discountYearlyPrice(30)
        )
        #expect(sut.savingText == Strings.Localizable.SubscriptionPurchase.Revamp.Cycle.saving("20%"))
    }

    @Test("Only the current plan's offer is excluded; another plan's offer still counts")
    func currentPlanOfferIsExcludedButOthersStillCount() {
        let current = discountedYearlyPlan(.proI, price: 100, introPrice: 20)
        let sut = SubscriptionCycleViewModel(
            plans: [current, discountedYearlyPlan(.proII, price: 100, introPrice: 60)],
            currentPlan: current,
            tracker: MockUpgradePlansAnalyticsUseCase()
        )
        #expect(sut.savingText == Strings.Localizable.SubscriptionPurchase.Revamp.Cycle.saving("40%"))
    }

    @Test("The current plan is left out of the base yearly-vs-monthly saving")
    func baseSavingExcludesCurrentPlan() {
        let sut = makeSUT(
            plans: [
                PlanEntity(type: .proI, subscriptionCycle: .monthly, price: 10),
                PlanEntity(type: .proI, subscriptionCycle: .yearly, price: 60),
                PlanEntity(type: .proII, subscriptionCycle: .monthly, price: 10),
                PlanEntity(type: .proII, subscriptionCycle: .yearly, price: 96)
            ],
            currentPlan: PlanEntity(type: .proI, subscriptionCycle: .yearly, price: 60),
            planPrice: .yearly(.init(price: 0, currency: ""))
        )
        #expect(sut.savingText == Strings.Localizable.SubscriptionPurchase.Revamp.Cycle.saving("20%"))
    }

    /// The monthly price of a current monthly plan must stay available, or the yearly plan of the
    /// same tier - which is still rendered - loses its base saving.
    @Test("A monthly current plan still feeds the base saving of its own yearly plan")
    func monthlyCurrentPlanStillFeedsItsYearlyBaseSaving() {
        let sut = makeSUT(
            plans: monthlyAndYearlyPlans,
            currentPlan: PlanEntity(type: .proI, subscriptionCycle: .monthly, price: 10),
            planPrice: .yearly(.init(price: 0, currency: ""))
        )
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
