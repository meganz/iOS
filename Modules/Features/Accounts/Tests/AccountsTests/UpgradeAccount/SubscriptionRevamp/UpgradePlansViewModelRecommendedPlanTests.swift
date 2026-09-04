@testable import Accounts
import Foundation
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@MainActor
@Suite("UpgradePlansViewModel - recommended plan ribbon")
struct UpgradePlansViewModelRecommendedPlanTests {

    /// Limits are generous by default so cycle-focused tests have headroom for a zero-usage account;
    /// the headroom test sets them explicitly.
    private func plan(
        _ productIdentifier: String,
        _ type: AccountTypeEntity,
        _ cycle: SubscriptionCycleEntity,
        price: Decimal,
        limit: Int = 2048
    ) -> PlanEntity {
        PlanEntity(
            productIdentifier: productIdentifier,
            type: type,
            subscriptionCycle: cycle,
            storageLimit: limit,
            transferLimit: limit,
            price: price
        )
    }

    /// The real recommendation use case, so the ribbon is exercised through the whole path.
    private func makeSUT(
        plans: [PlanEntity],
        proLevel: AccountTypeEntity = .free,
        userCycle: SubscriptionCycleEntity = .none,
        storageUsed: Int64 = 0,
        isPromo: Bool = false
    ) -> UpgradePlansViewModel {
        UpgradePlansViewModel(
            isPromo: isPromo,
            viewType: .upgrade,
            accountDetails: .build(storageUsed: storageUsed, proLevel: proLevel, subscriptionCycle: userCycle),
            plans: plans,
            displayName: { _ in "" }
        )
    }

    private func recommendedProductIdentifier(
        _ sut: UpgradePlansViewModel,
        for cycle: SubscriptionCycleEntity
    ) -> String? {
        sut.planCards(for: cycle).first { $0.ribbon == .recommended }?.productIdentifier
    }

    /// The asymmetric catalog: Pro Lite is sold yearly only. Resolving the tier once would tag the yearly
    /// list and leave the monthly list with no ribbon at all, because that tier has no monthly product.
    @Test("A tier sold only yearly still leaves the monthly list with its own recommendation")
    func asymmetricCatalog_bothCyclesCarryARibbon() {
        let sut = makeSUT(plans: [
            plan("lite.yearly", .lite, .yearly, price: 30),
            plan("proI.yearly", .proI, .yearly, price: 100),
            plan("proI.monthly", .proI, .monthly, price: 10),
            plan("proII.monthly", .proII, .monthly, price: 20)
        ])

        #expect(recommendedProductIdentifier(sut, for: .yearly) == "lite.yearly")
        #expect(recommendedProductIdentifier(sut, for: .monthly) == "proI.monthly")
    }

    /// The recommendation follows the cycle being rendered, not the cycle the account is billed on.
    @Test("A monthly subscriber viewing the yearly list sees the cheapest yearly plan tagged")
    func monthlySubscriber_viewingYearly_seesAYearlyRecommendation() {
        let sut = makeSUT(
            plans: [
                plan("proII.monthly", .proII, .monthly, price: 20),
                plan("proII.yearly", .proII, .yearly, price: 200),
                plan("proIII.yearly", .proIII, .yearly, price: 300)
            ],
            proLevel: .proI,
            userCycle: .monthly
        )

        #expect(recommendedProductIdentifier(sut, for: .yearly) == "proII.yearly")
        #expect(recommendedProductIdentifier(sut, for: .monthly) == "proII.monthly")
    }

    @Test("The recommended card is the primary action and the others are not")
    func recommendedCardIsTheOnlyPrimaryAction() {
        let sut = makeSUT(plans: [
            plan("proI.monthly", .proI, .monthly, price: 10),
            plan("proII.monthly", .proII, .monthly, price: 20)
        ])
        let cards = sut.planCards(for: .monthly)

        #expect(cards.filter(\.isPrimaryAction).map(\.productIdentifier) == ["proI.monthly"])
    }

    @Test("No ribbon when no plan in that cycle clears the account's allowance")
    func noEligiblePlanInTheCycle_leavesTheListUnribboned() {
        let sut = makeSUT(
            plans: [plan("proI.monthly", .proI, .monthly, price: 10, limit: 400)],
            proLevel: .proI,
            userCycle: .yearly,
            storageUsed: 4096.gigabytesToBytes()
        )
        let cards = sut.planCards(for: .monthly)

        #expect(cards.count == 1)
        #expect(cards.allSatisfy { $0.ribbon == nil })
    }

    @Test("The promo page never tags a recommended tier")
    func promoPage_hasNoRecommendedRibbon() {
        let sut = makeSUT(
            plans: [plan("proI.monthly", .proI, .monthly, price: 10), plan("proI.yearly", .proI, .yearly, price: 100)],
            isPromo: true
        )

        #expect(recommendedProductIdentifier(sut, for: .monthly) == nil)
        #expect(recommendedProductIdentifier(sut, for: .yearly) == nil)
    }
}
