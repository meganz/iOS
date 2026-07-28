import Foundation
import MEGADomain
import MEGADomainMock
import Testing

struct SubscriptionPlanPriceUseCaseTests {
    private let sut = SubscriptionPlanPriceUseCase()

    private func plan(
        currency: String = "EUR",
        subscriptionCycle: SubscriptionCycleEntity,
        price: Decimal,
        introductoryOffer: IntroductoryOfferEntity? = nil
    ) -> PlanEntity {
        PlanEntity(
            currency: currency,
            subscriptionCycle: subscriptionCycle,
            price: price,
            introductoryOffer: introductoryOffer
        )
    }

    // MARK: - No offer

    @Test func monthlyPlan_noOffer_mapsToMonthly() {
        let result = sut.planPrice(for: plan(subscriptionCycle: .monthly, price: 10))
        #expect(result == .monthly(.init(price: 10, currency: "EUR")))
    }

    @Test func yearlyPlan_noOffer_mapsToYearly() {
        let result = sut.planPrice(for: plan(subscriptionCycle: .yearly, price: 120))
        #expect(result == .yearly(.init(price: 120, currency: "EUR")))
    }

    @Test func noneCycle_noOffer_mapsToMonthly() {
        let result = sut.planPrice(for: plan(subscriptionCycle: .none, price: 10))
        #expect(result == .monthly(.init(price: 10, currency: "EUR")))
    }

    // MARK: - Discount monthly

    @Test func monthlyPlan_payUpFront_mapsToPrepaidSchedule() {
        // 6-month up-front offer at 30 total; full monthly 10.
        let offer = IntroductoryOfferEntity(
            price: 30,
            period: .init(unit: .month, value: 6),
            periodCount: 1,
            paymentMode: .payUpFront
        )
        let result = sut.planPrice(for: plan(subscriptionCycle: .monthly, price: 10, introductoryOffer: offer))
        #expect(result == .discountMonthly(.init(
            monthly: .init(price: 10, currency: "EUR"),
            offer: .init(
                originalPrice: 60,          // full monthly × 6 months
                discountPercentage: 50,     // 30 vs 60 over 6 months
                schedule: .prepaid(price: 30, period: .init(unit: .month, value: 6))
            )
        )))
    }

    @Test func monthlyPlan_payAsYouGo_mapsToRecurringSchedule() {
        // 6 × 1-month periods at 5 each; full monthly 10.
        let offer = IntroductoryOfferEntity(
            price: 5,
            period: .init(unit: .month, value: 1),
            periodCount: 6,
            paymentMode: .payAsYouGo
        )
        let result = sut.planPrice(for: plan(subscriptionCycle: .monthly, price: 10, introductoryOffer: offer))
        #expect(result == .discountMonthly(.init(
            monthly: .init(price: 10, currency: "EUR"),
            offer: .init(
                originalPrice: 10,          // full monthly (recurring strikes per-month)
                discountPercentage: 50,     // 5/month vs 10/month
                schedule: .recurring(price: 5, period: .init(unit: .month, value: 1), periodCount: 6)
            )
        )))
    }

    @Test func monthlyPlan_freeTrial_mapsToFreeSchedule() {
        // 1-month free trial; full monthly 10.
        let offer = IntroductoryOfferEntity(
            price: 0,
            period: .init(unit: .month, value: 1),
            periodCount: 1,
            paymentMode: .freeTrial
        )
        let result = sut.planPrice(for: plan(subscriptionCycle: .monthly, price: 10, introductoryOffer: offer))
        #expect(result == .discountMonthly(.init(
            monthly: .init(price: 10, currency: "EUR"),
            offer: .init(
                originalPrice: 10,          // full monthly × 1 month
                discountPercentage: 100,    // free
                schedule: .free(period: .init(unit: .month, value: 1))
            )
        )))
    }

    // MARK: - Discount yearly

    @Test func yearlyPlan_payUpFrontOneYear_mapsToPrepaidSchedule() {
        // 1-year up-front offer at 60; full yearly 120.
        let offer = IntroductoryOfferEntity(
            price: 60,
            period: .init(unit: .year, value: 1),
            periodCount: 1,
            paymentMode: .payUpFront
        )
        let result = sut.planPrice(for: plan(subscriptionCycle: .yearly, price: 120, introductoryOffer: offer))
        #expect(result == .discountYearly(.init(
            yearly: .init(price: 120, currency: "EUR"),
            offer: .init(
                originalPrice: 120,         // (120 × 12) / 12
                discountPercentage: 50,     // 60 vs 120 over 12 months
                schedule: .prepaid(price: 60, period: .init(unit: .year, value: 1))
            )
        )))
    }

    @Test func yearlyPlan_payAsYouGoOneYear_mapsToRecurringSchedule() {
        // Per Apple's table, a yearly plan's pay-as-you-go offer is 1 year.
        let offer = IntroductoryOfferEntity(
            price: 60,
            period: .init(unit: .year, value: 1),
            periodCount: 1,
            paymentMode: .payAsYouGo
        )
        let result = sut.planPrice(for: plan(subscriptionCycle: .yearly, price: 120, introductoryOffer: offer))
        #expect(result == .discountYearly(.init(
            yearly: .init(price: 120, currency: "EUR"),
            offer: .init(
                originalPrice: 120,
                discountPercentage: 50,
                schedule: .recurring(price: 60, period: .init(unit: .year, value: 1), periodCount: 1)
            )
        )))
    }

    @Test func yearlyPlan_sixMonthOffer_strikethroughIsPrecise() {
        // Full yearly 119.88 → 6-month struck price must be exactly 59.94 (multiply-before-divide).
        let offer = IntroductoryOfferEntity(
            price: Decimal(string: "29.94")!,
            period: .init(unit: .month, value: 6),
            periodCount: 1,
            paymentMode: .payUpFront
        )
        let result = sut.planPrice(for: plan(
            subscriptionCycle: .yearly,
            price: Decimal(string: "119.88")!,
            introductoryOffer: offer
        ))
        #expect(result == .discountYearly(.init(
            yearly: .init(price: Decimal(string: "119.88")!, currency: "EUR"),
            offer: .init(
                originalPrice: Decimal(string: "59.94")!,
                discountPercentage: 50,
                schedule: .prepaid(price: Decimal(string: "29.94")!, period: .init(unit: .month, value: 6))
            )
        )))
    }

    // MARK: - Discount percentage (moved from PlanEntity.introOfferDiscountPercentage)

    @Test(
        arguments: [
            // fullYearlyPrice, introYearlyPrice, expectedPercentage
            (Decimal(100), Decimal(80), 20),
            (Decimal(100), Decimal(50), 50),
            (Decimal(100), Decimal(string: "90.5")!, 10), // 9.5% → rounds to 10 (single-division precision)
            (Decimal(100), Decimal(string: "89.4")!, 11),
            (Decimal(string: "1.99")!, Decimal(string: "0.99")!, 50)
        ]
    )
    func discountPercentage_yearly(fullPrice: Decimal, introPrice: Decimal, expected: Int) {
        let offer = IntroductoryOfferEntity(
            price: introPrice,
            period: .init(unit: .year, value: 1),
            periodCount: 1,
            paymentMode: .payUpFront
        )
        let result = sut.planPrice(for: plan(subscriptionCycle: .yearly, price: fullPrice, introductoryOffer: offer))
        #expect(result.discountPercentage == expected)
    }

    @Test func discountPercentage_isNilForPlainPrice() {
        #expect(sut.planPrice(for: plan(subscriptionCycle: .yearly, price: 120)).discountPercentage == nil)
        #expect(sut.planPrice(for: plan(subscriptionCycle: .monthly, price: 10)).discountPercentage == nil)
    }

    @Test func discountPercentage_isZeroForDegenerateOffer() {
        // Non-positive full price → guard avoids dividing by zero and yields 0 (ribbon treats as no discount).
        let offer = IntroductoryOfferEntity(
            price: 30,
            period: .init(unit: .month, value: 6),
            periodCount: 1,
            paymentMode: .payUpFront
        )
        let result = sut.planPrice(for: plan(subscriptionCycle: .yearly, price: 0, introductoryOffer: offer))
        #expect(result.discountPercentage == 0)
    }

    // MARK: - Promotional offer discount percentage

    private func mobileOffer(discountPercentage: Int) -> MobileOfferEntity {
        MobileOfferEntity(
            id: "promo",
            useAsTitle: false,
            label: nil,
            discountPercentage: discountPercentage,
            flags: 0,
            reshowTimeout: nil,
            expiryDate: nil,
            iosOfferId: "offer-id",
            iosSignature: MobileOfferIosSignatureEntity(
                offerId: "offer-id", keyId: "key", nonce: "nonce", timestamp: 0, signature: "sig"
            )
        )
    }

    private func promoPlan(apiDiscountPercentage: Int) -> PlanEntity {
        // A payAsYouGo promo of 5/month against a 10/month plan computes to 50%.
        PlanEntity(
            currency: "EUR",
            subscriptionCycle: .monthly,
            price: 10,
            mobileOffer: mobileOffer(discountPercentage: apiDiscountPercentage),
            promotionalOffer: PromotionalOfferEntity(
                price: 5,
                period: .init(unit: .month, value: 1),
                periodCount: 6,
                paymentMode: .payAsYouGo
            )
        )
    }

    @Test func promotionalOffer_usesApiDiscountPercentage_notBillingCycleFormula() {
        // API says 40%; the billing-cycle formula would compute 50% → the API value is used.
        let result = sut.planPrice(for: promoPlan(apiDiscountPercentage: 40))
        #expect(result.discountPercentage == 40)
    }

    @Test func promotionalOffer_usesApiDiscountPercentageDirectly_evenWhenZero() {
        // The formula would compute 50%, but the API value (0) is used as-is; no fallback.
        let result = sut.planPrice(for: promoPlan(apiDiscountPercentage: 0))
        #expect(result.discountPercentage == 0)
    }
}
