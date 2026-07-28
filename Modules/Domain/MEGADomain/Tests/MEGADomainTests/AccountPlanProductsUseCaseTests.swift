import MEGADomain
import MEGADomainMock
import Testing

struct AccountPlanProductsUseCaseTests {
    // `currency:` disambiguates to the string-price initializer (the appStorePrice one lacks it).
    private func plan(type: AccountTypeEntity, cycle: SubscriptionCycleEntity) -> PlanEntity {
        PlanEntity(type: type, currency: "EUR", subscriptionCycle: cycle)
    }

    private func makeSUT(
        plans: [PlanEntity],
        offers: [PlanEntity: SubscriptionOfferEntity] = [:],
        promotionalOffers: [PlanEntity: SubscriptionOfferEntity] = [:]
    ) -> AccountPlanProductsUseCase {
        AccountPlanProductsUseCase(
            purchaseUseCase: MockAccountPlanPurchaseUseCase(accountPlanProducts: plans),
            offerUseCase: MockStoreKitOfferUseCase(introductoryOfferDict: offers, promotionalOfferDict: promotionalOffers)
        )
    }

    @Test func availablePlans_mergesFetchedOffersOntoMatchingPlans() async {
        let proI = plan(type: .proI, cycle: .yearly)
        let proII = plan(type: .proII, cycle: .yearly)
        let offer = SubscriptionOfferEntity(price: 50, period: .init(unit: .month, value: 12), periodCount: 1, paymentMode: .payUpFront)

        let result = await makeSUT(plans: [proI, proII], offers: [proI: offer]).availablePlans()

        #expect(result.count == 2)
        #expect(result.first { $0.type == .proI }?.introductoryOffer?.price == 50)
        #expect(result.first { $0.type == .proII }?.introductoryOffer == nil)
    }

    @Test func availablePlans_mergesFetchedPromotionalOffersOntoMatchingPlans() async {
        let proI = plan(type: .proI, cycle: .yearly)
        let proII = plan(type: .proII, cycle: .yearly)
        let promo = SubscriptionOfferEntity(price: 30, period: .init(unit: .month, value: 12), periodCount: 1, paymentMode: .payUpFront)

        let result = await makeSUT(plans: [proI, proII], promotionalOffers: [proI: promo]).availablePlans()

        #expect(result.first { $0.type == .proI }?.promotionalOffer?.price == 30)
        #expect(result.first { $0.type == .proII }?.promotionalOffer == nil)
    }

    @Test func availablePlans_mergesBothIntroductoryAndPromotionalOffers() async {
        let proI = plan(type: .proI, cycle: .yearly)
        let intro = SubscriptionOfferEntity(price: 10, period: .init(unit: .month, value: 12), periodCount: 1, paymentMode: .payUpFront)
        let promo = SubscriptionOfferEntity(price: 20, period: .init(unit: .month, value: 12), periodCount: 1, paymentMode: .payUpFront)

        let result = await makeSUT(plans: [proI], offers: [proI: intro], promotionalOffers: [proI: promo]).availablePlans()

        #expect(result.first?.introductoryOffer?.price == 10)
        #expect(result.first?.promotionalOffer?.price == 20)
    }

    @Test func availablePlans_noOffers_leavesPlansUnchanged() async {
        let plans = [plan(type: .proI, cycle: .yearly), plan(type: .proII, cycle: .monthly)]

        let result = await makeSUT(plans: plans, offers: [:]).availablePlans()

        #expect(result.allSatisfy { $0.introductoryOffer == nil })
    }

    @Test func availablePlans_emptyCatalog_returnsEmpty() async {
        let result = await makeSUT(plans: [], offers: [:]).availablePlans()
        #expect(result.isEmpty)
    }
}
