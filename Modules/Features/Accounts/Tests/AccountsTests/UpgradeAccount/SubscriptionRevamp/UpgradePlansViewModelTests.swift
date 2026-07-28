@testable import Accounts
import MEGADomain
import MEGADomainMock
import Testing

@MainActor
@Suite("UpgradePlansViewModel - default cycle selection")
struct UpgradePlansViewModelTests {

    private func introOffer() -> IntroductoryOfferEntity {
        IntroductoryOfferEntity(price: 1, period: .init(unit: .month, value: 1), periodCount: 1, paymentMode: .payAsYouGo)
    }

    private func plan(_ cycle: SubscriptionCycleEntity, discounted: Bool = false) -> PlanEntity {
        PlanEntity(
            type: .proI,
            subscriptionCycle: cycle,
            price: 10,
            introductoryOffer: discounted ? introOffer() : nil
        )
    }

    private func makeSUT(
        plans: [PlanEntity],
        userCycle: SubscriptionCycleEntity = .none
    ) -> UpgradePlansViewModel {
        UpgradePlansViewModel(
            viewType: .upgrade,
            accountDetails: .build(subscriptionCycle: userCycle),
            plans: plans,
            displayName: { _ in "" }
        )
    }

    @Test("A discount on the monthly cycle only preselects monthly, overriding the user's cycle")
    func monthlyOnlyDiscountPreselectsMonthly() {
        let sut = makeSUT(plans: [plan(.monthly, discounted: true), plan(.yearly)], userCycle: .yearly)
        #expect(sut.defaultSelectedCycle == .monthly)
    }

    @Test("A discount on the yearly cycle only preselects yearly, overriding the user's cycle")
    func yearlyOnlyDiscountPreselectsYearly() {
        let sut = makeSUT(plans: [plan(.monthly), plan(.yearly, discounted: true)], userCycle: .monthly)
        #expect(sut.defaultSelectedCycle == .yearly)
    }

    @Test("Discounts on both cycles preselect the cycle matching the user's current plan (monthly)")
    func bothDiscountedFollowsUserCycleMonthly() {
        let sut = makeSUT(
            plans: [plan(.monthly, discounted: true), plan(.yearly, discounted: true)],
            userCycle: .monthly
        )
        #expect(sut.defaultSelectedCycle == .monthly)
    }

    @Test("Discounts on both cycles preselect the cycle matching the user's current plan (yearly)")
    func bothDiscountedFollowsUserCycleYearly() {
        let sut = makeSUT(
            plans: [plan(.monthly, discounted: true), plan(.yearly, discounted: true)],
            userCycle: .yearly
        )
        #expect(sut.defaultSelectedCycle == .yearly)
    }

    @Test("Discounts on both cycles fall back to yearly when the user has no recurring plan")
    func bothDiscountedDefaultsToYearlyWithoutUserCycle() {
        let sut = makeSUT(
            plans: [plan(.monthly, discounted: true), plan(.yearly, discounted: true)],
            userCycle: .none
        )
        #expect(sut.defaultSelectedCycle == .yearly)
    }

    @Test("No discount preselects the user's current cycle (monthly)")
    func noDiscountFollowsUserCycleMonthly() {
        let sut = makeSUT(plans: [plan(.monthly), plan(.yearly)], userCycle: .monthly)
        #expect(sut.defaultSelectedCycle == .monthly)
    }

    @Test("No discount preselects the user's current cycle (yearly)")
    func noDiscountFollowsUserCycleYearly() {
        let sut = makeSUT(plans: [plan(.monthly), plan(.yearly)], userCycle: .yearly)
        #expect(sut.defaultSelectedCycle == .yearly)
    }

    @Test("No discount and no user cycle defaults to yearly")
    func noDiscountNoUserCycleDefaultsToYearly() {
        let sut = makeSUT(plans: [plan(.monthly), plan(.yearly)], userCycle: .none)
        #expect(sut.defaultSelectedCycle == .yearly)
    }
}
