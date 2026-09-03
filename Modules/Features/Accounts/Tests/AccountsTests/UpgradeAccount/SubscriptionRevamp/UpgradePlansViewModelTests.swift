@testable import Accounts
import MEGADomain
import MEGADomainMock
import Testing

@MainActor
@Suite("UpgradePlansViewModel - default cycle selection")
struct UpgradePlansViewModelTests {

    private func introOffer() -> SubscriptionOfferEntity {
        SubscriptionOfferEntity(price: 1, period: .init(unit: .month, value: 1), periodCount: 1, paymentMode: .payAsYouGo)
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

    @Test("A discount on the monthly cycle only preselects monthly")
    func monthlyOnlyDiscountPreselectsMonthly() {
        let sut = makeSUT(plans: [plan(.monthly, discounted: true), plan(.yearly)], userCycle: .monthly)
        #expect(sut.defaultSelectedCycle == .monthly)
        #expect(sut.selectedCycle == .monthly)
    }

    @Test("A discount on the yearly cycle only preselects yearly")
    func yearlyOnlyDiscountPreselectsYearly() {
        let sut = makeSUT(plans: [plan(.monthly), plan(.yearly, discounted: true)], userCycle: .monthly)
        #expect(sut.defaultSelectedCycle == .yearly)
        #expect(sut.selectedCycle == .yearly)
    }

    @Test("Discounts on both cycles preselect yearly")
    func bothDiscountedPreselectsYearly() {
        let sut = makeSUT(
            plans: [plan(.monthly, discounted: true), plan(.yearly, discounted: true)],
            userCycle: .monthly
        )
        #expect(sut.defaultSelectedCycle == .yearly)
        #expect(sut.selectedCycle == .yearly)
    }

    @Test("A user on a monthly plan still preselects yearly")
    func monthlyUserCyclePreselectsYearly() {
        let sut = makeSUT(plans: [plan(.monthly), plan(.yearly)], userCycle: .monthly)
        #expect(sut.defaultSelectedCycle == .yearly)
        #expect(sut.selectedCycle == .yearly)
    }

    @Test("A user with no recurring plan preselects yearly")
    func noUserCyclePreselectsYearly() {
        let sut = makeSUT(plans: [plan(.monthly), plan(.yearly)], userCycle: .none)
        #expect(sut.defaultSelectedCycle == .yearly)
        #expect(sut.selectedCycle == .yearly)
    }
}
