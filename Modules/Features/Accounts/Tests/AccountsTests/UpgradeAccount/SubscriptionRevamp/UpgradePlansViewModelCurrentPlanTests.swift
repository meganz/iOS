@testable import Accounts
import Foundation
import MEGADomain
import MEGADomainMock
import MEGAL10n
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

    // MARK: - featuredPlan

    @Test("There is no featured plan on the standard page, even with a single discounted plan")
    func featuredPlanIsNilOnStandardPage() {
        let sut = makeSUT(plans: [plan(.proII, .yearly, discounted: true)], isPromo: false)
        #expect(sut.featuredPlan == nil)
        #expect(sut.highlightedPlanCard == nil)
    }

    @Test("The single discounted plan is the featured plan on the promo page")
    func featuredPlanIsTheDiscountedPlanOnPromoPage() {
        let discounted = plan(.proII, .yearly, discounted: true)
        let sut = makeSUT(plans: [discounted], isPromo: true)
        #expect(sut.featuredPlan == discounted)
    }

    // MARK: - promoHeader

    /// A yearly plan discounted by a 1-year pay-up-front intro offer, so each plan carries its own percentage.
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

    @Test("The promo header skips the current plan when picking the deepest discount")
    func promoHeaderSkipsCurrentPlan() {
        let current = discountedYearlyPlan(.proI, price: 100, introPrice: 20)
        let sut = makeSUT(
            plans: [current, discountedYearlyPlan(.proII, price: 100, introPrice: 60)],
            proLevel: .proI,
            userCycle: .yearly
        )
        #expect(
            sut.promoHeader?.subtitle == Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOffer("40%")
        )
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
