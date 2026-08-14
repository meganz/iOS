@testable import Accounts
import MEGADomain
import MEGAL10n
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
        featuredPlan: PlanEntity? = nil,
        externalPurchase: ExternalPurchasePresenter? = nil
    ) -> SubscriptionPlanCardsPresenter {
        SubscriptionPlanCardsPresenter(
            plans: plans,
            pageType: .promo(featuredPlan: featuredPlan),
            displayName: { $0.toAccountTypeDisplayName() },
            externalPurchase: externalPurchase
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
        #expect(card.storage == Strings.Localizable.SubscriptionPurchase.Plan.storage("2 TB"))
        #expect(card.transfer == Strings.Localizable.SubscriptionPurchase.Plan.transfer("2 TB"))
        #expect(card.ribbon == nil)
        #expect(card.hasOffer == false)
    }

    @Test("Storage and transfer are labelled, not raw plan values")
    func labelsStorageAndTransfer() throws {
        let sut = makeSUT(plans: [plan(.proII, .yearly, storage: "8 TB", transfer: "8 TB")])
        let card = try #require(sut.cards(for: .yearly).first)
        #expect(card.storage != "8 TB")
        #expect(card.storage.contains("8 TB"))
        #expect(card.transfer != "8 TB")
        #expect(card.transfer.contains("8 TB"))
    }

    // MARK: - Buy on our website

    @Test("Without the external purchase capability no card offers the buy on our website button")
    func withoutExternalPurchase_cardsHaveNoExternalPurchaseTitle() {
        let sut = makeSUT(plans: [externalPurchasePlan()])
        #expect(sut.cards(for: .monthly).map(\.externalPurchaseTitle) == [nil])
    }

    @Test("A plan with an API price and no offer carries the buy on our website title")
    func withExternalPurchase_planWithAPIPriceAndNoOffer_carriesTheTitle() throws {
        let sut = makeSUT(plans: [externalPurchasePlan()], externalPurchase: ExternalPurchasePresenter())
        let card = try #require(sut.cards(for: .monthly).first)
        #expect(card.externalPurchaseTitle == Strings.Localizable.SubscriptionPurchase.Revamp.Button.BuyOnWebsite.saveUpTo("10%"))
    }

    @Test("A discounted plan carries no buy on our website title")
    func withExternalPurchase_planWithOffer_carriesNoTitle() {
        let sut = makeSUT(
            plans: [externalPurchasePlan(introductoryOffer: introOffer())],
            externalPurchase: ExternalPurchasePresenter()
        )
        #expect(sut.cards(for: .monthly).map(\.externalPurchaseTitle) == [nil])
    }

    @Test("A plan without an API price carries no buy on our website title")
    func withExternalPurchase_planWithoutAPIPrice_carriesNoTitle() {
        let sut = makeSUT(plans: [externalPurchasePlan(apiPrice: nil)], externalPurchase: ExternalPurchasePresenter())
        #expect(sut.cards(for: .monthly).map(\.externalPurchaseTitle) == [nil])
    }

    // MARK: - Buy on our website fixtures

    private func externalPurchasePlan(
        apiPrice: PlanPriceEntity? = PlanPriceEntity(price: 9, formattedPrice: "$9.00", currency: "USD"),
        introductoryOffer: SubscriptionOfferEntity? = nil
    ) -> PlanEntity {
        PlanEntity(
            productIdentifier: "pro1.oneMonth",
            type: .proI,
            subscriptionCycle: .monthly,
            apiPrice: apiPrice,
            appStorePrice: PlanPriceEntity(price: 10, formattedPrice: "$10.00", currency: "USD"),
            introductoryOffer: introductoryOffer
        )
    }

    private func introOffer() -> SubscriptionOfferEntity {
        SubscriptionOfferEntity(
            price: 5,
            period: .init(unit: .month, value: 1),
            periodCount: 1,
            paymentMode: .payAsYouGo
        )
    }
}
