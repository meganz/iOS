@testable import Accounts
import MEGADomain
import Testing

@Suite("SubscriptionPlanCardsPresenter - standard plan card list")
struct SubscriptionPlanCardsPresenterTests {

    private func plan(
        _ type: AccountTypeEntity,
        _ cycle: SubscriptionCycleEntity,
        storage: String = "",
        transfer: String = ""
    ) -> PlanEntity {
        PlanEntity(type: type, subscriptionCycle: cycle, storage: storage, transfer: transfer)
    }

    private func makeSUT(
        plans: [PlanEntity],
        featuredPlan: PlanEntity? = nil
    ) -> SubscriptionPlanCardsPresenter {
        SubscriptionPlanCardsPresenter(
            plans: plans,
            featuredPlan: featuredPlan,
            displayName: { $0.toAccountTypeDisplayName() }
        )
    }

    @Test("Only plans matching the requested cycle are returned")
    func filtersToRequestedCycle() {
        let sut = makeSUT(plans: [plan(.proI, .monthly), plan(.proII, .yearly)])
        #expect(sut.cards(for: .monthly).map(\.title) == [AccountTypeEntity.proI.toAccountTypeDisplayName()])
    }

    @Test("The featured plan is excluded from its own cycle")
    func excludesFeaturedPlanInItsOwnCycle() {
        let featured = plan(.proI, .yearly)
        let sut = makeSUT(plans: [featured, plan(.proII, .yearly)], featuredPlan: featured)
        #expect(sut.cards(for: .yearly).map(\.title) == [AccountTypeEntity.proII.toAccountTypeDisplayName()])
    }

    @Test("The featured plan's same-type variant in another cycle is kept")
    func keepsSameTypeVariantInOtherCycle() {
        let featured = plan(.proI, .yearly)
        let sut = makeSUT(
            plans: [featured, plan(.proI, .monthly), plan(.proII, .monthly)],
            featuredPlan: featured
        )
        let titles = sut.cards(for: .monthly).map(\.title)
        #expect(titles.contains(AccountTypeEntity.proI.toAccountTypeDisplayName()))
        #expect(titles.count == 2)
    }

    @Test("All plans for the cycle are returned when there is no featured plan")
    func includesAllWhenNoFeaturedPlan() {
        let sut = makeSUT(plans: [plan(.proI, .monthly), plan(.proII, .monthly)])
        #expect(sut.cards(for: .monthly).count == 2)
    }

    @Test("Maps the plan's title, storage and transfer; a plan with no offer has no ribbon")
    func mapsPlanFields() throws {
        let sut = makeSUT(plans: [plan(.proI, .monthly, storage: "2 TB", transfer: "2 TB")])
        let card = try #require(sut.cards(for: .monthly).first)
        #expect(card.title == AccountTypeEntity.proI.toAccountTypeDisplayName())
        #expect(card.storage == "2 TB")
        #expect(card.transfer == "2 TB")
        #expect(card.ribbonText == nil)
        #expect(card.hasOffer == false)
    }
}
