@testable import Accounts
import MEGADomain
import MEGADomainMock
import Testing

@MainActor
@Suite("UpgradePlansViewModel - current plan exclusion")
struct UpgradePlansViewModelCurrentPlanTests {

    private func introOffer() -> SubscriptionOfferEntity {
        SubscriptionOfferEntity(price: 1, period: .init(unit: .month, value: 1), periodCount: 1, paymentMode: .payAsYouGo)
    }

    private func plan(
        _ type: AccountTypeEntity,
        _ cycle: SubscriptionCycleEntity,
        discounted: Bool = false
    ) -> PlanEntity {
        PlanEntity(
            type: type,
            subscriptionCycle: cycle,
            price: 10,
            introductoryOffer: discounted ? introOffer() : nil
        )
    }

    private func makeSUT(
        plans: [PlanEntity],
        proLevel: AccountTypeEntity = .free,
        userCycle: SubscriptionCycleEntity = .none,
        isPromo: Bool = true
    ) -> UpgradePlansViewModel {
        UpgradePlansViewModel(
            isPromo: isPromo,
            viewType: .upgrade,
            accountDetails: .build(proLevel: proLevel, subscriptionCycle: userCycle),
            plans: plans,
            displayName: { _ in "" }
        )
    }

    // MARK: - highlightedPlanCard

    @Test("The hero card is hidden when the only discounted plan is the user's current plan")
    func heroHiddenWhenDiscountedPlanIsCurrent() {
        let sut = makeSUT(
            plans: [plan(.proI, .monthly, discounted: true)],
            proLevel: .proI,
            userCycle: .monthly
        )
        #expect(sut.highlightedPlanCard == nil)
    }

    @Test("The hero card is shown when the discounted plan is a different level than the current plan")
    func heroShownForDifferentLevel() {
        let sut = makeSUT(
            plans: [plan(.proII, .monthly, discounted: true)],
            proLevel: .proI,
            userCycle: .monthly
        )
        #expect(sut.highlightedPlanCard != nil)
    }

    @Test("The hero card is shown when the discounted plan matches the level but not the cycle of the current plan")
    func heroShownForSameLevelDifferentCycle() {
        let sut = makeSUT(
            plans: [plan(.proI, .yearly, discounted: true)],
            proLevel: .proI,
            userCycle: .monthly
        )
        #expect(sut.highlightedPlanCard != nil)
    }

    // MARK: - planCards

    @Test("planCards excludes the user's current plan from the requested cycle")
    func planCardsExcludesCurrentPlan() {
        let sut = makeSUT(
            plans: [plan(.proI, .monthly), plan(.proII, .monthly)],
            proLevel: .proI,
            userCycle: .monthly,
            isPromo: false
        )
        #expect(sut.planCards(for: .monthly).count == 1)
    }

    @Test("planCards keeps a same-level plan billed on a different cycle than the current plan")
    func planCardsKeepsSameLevelDifferentCycle() {
        let sut = makeSUT(
            plans: [plan(.proI, .monthly), plan(.proII, .monthly)],
            proLevel: .proI,
            userCycle: .yearly,
            isPromo: false
        )
        #expect(sut.planCards(for: .monthly).count == 2)
    }
}
