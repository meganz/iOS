import Foundation
import MEGADomain
import MEGADomainMock
import Testing

struct PlanEntityTests {

    // MARK: - introDiscountPercentage (legacy — only valid for a 1-year pay-up-front offer)

    @Test(
        arguments: [
            (100, 80, 20),
            (100, 50, 50),
            (100, 90.5, 10),
            (100, 89.4, 11),
            (1.99, 0.99, 50)
        ]
    )
    func introDiscountPercentage(
        fullPrice: Decimal,
        introPrice: Decimal,
        expectedPercentage: Int
    ) {
        let introOffer = IntroductoryOfferEntity(
            price: introPrice,
            period: .init(unit: .year, value: 1),
            periodCount: 1
        )
        let plan = PlanEntity(
            type: .proI,
            subscriptionCycle: .yearly,
            appStorePrice: .init(price: fullPrice, formattedPrice: "$100", currency: "USD"),
            introductoryOffer: introOffer
        )

        #expect(plan.introDiscountPercentage == expectedPercentage)
    }

    @Test
    func introDiscountPercentage_whenFullPriceIsZero_shouldBeNil() {
        let introOffer = IntroductoryOfferEntity(
            price: 0,
            period: .init(unit: .year, value: 1),
            periodCount: 1
        )
        let plan = PlanEntity(
            type: .proI,
            subscriptionCycle: .yearly,
            appStorePrice: .init(price: 0, formattedPrice: "$0", currency: "USD"),
            introductoryOffer: introOffer
        )

        #expect(plan.introDiscountPercentage == nil)
    }

    @Test
    func introDiscountPercentage_whenWithoutIntroOffer_shouldBeNil() {
        let plan = PlanEntity(
            type: .proI,
            subscriptionCycle: .yearly,
            appStorePrice: .init(price: 100, formattedPrice: "$100", currency: "USD"),
            introductoryOffer: nil
        )

        #expect(plan.introDiscountPercentage == nil)
    }

    // MARK: - introOfferDiscountPercentage (span-aware — correct for all offer shapes)

    @Test(
        arguments: [
            (100, 80, 20),
            (100, 50, 50),
            (100, 90.5, 10), // Repeating-decimal rounding case (see whenResultIsAHalf below)
            (100, 89.4, 11),
            (1.99, 0.99, 50)
        ]
    )
    func introOfferDiscountPercentage(
        fullPrice: Decimal,
        introPrice: Decimal,
        expectedPercentage: Int
    ) {
        let introOffer = IntroductoryOfferEntity(
            price: introPrice,
            period: .init(unit: .year, value: 1),
            periodCount: 1
        )
        let plan = PlanEntity(
            type: .proI,
            subscriptionCycle: .yearly,
            appStorePrice: .init(price: fullPrice, formattedPrice: "$100", currency: "USD"),
            introductoryOffer: introOffer
        )

        #expect(plan.introOfferDiscountPercentage == expectedPercentage)
    }

    @Test
    func introOfferDiscountPercentage_whenMultiMonthPayUpFront_comparesOverSameSpan() {
        // Yearly plan full price 120 → 10/month. Intro is a 6-month up-front offer at 30 → 5/month.
        // Discount over the same (monthly) span is (10 - 5) / 10 = 50%.
        let introOffer = IntroductoryOfferEntity(
            price: 30,
            period: .init(unit: .month, value: 6),
            periodCount: 1,
            paymentMode: .payUpFront
        )
        let plan = PlanEntity(
            type: .proI,
            subscriptionCycle: .yearly,
            appStorePrice: .init(price: 120, formattedPrice: "$120", currency: "USD"),
            introductoryOffer: introOffer
        )

        #expect(plan.introOfferDiscountPercentage == 50)
    }

    @Test
    func introOfferDiscountPercentage_whenMonthlyPlan_comparesOverSameSpan() {
        // Monthly plan full price 10/month, 1-month intro at 8/month → (10 - 8) / 10 = 20%.
        let introOffer = IntroductoryOfferEntity(
            price: 8,
            period: .init(unit: .month, value: 1),
            periodCount: 1,
            paymentMode: .payAsYouGo
        )
        let plan = PlanEntity(
            type: .proI,
            subscriptionCycle: .monthly,
            appStorePrice: .init(price: 10, formattedPrice: "$10", currency: "USD"),
            introductoryOffer: introOffer
        )

        #expect(plan.introOfferDiscountPercentage == 20)
    }

    @Test
    func introOfferDiscountPercentage_whenResultIsAHalf_roundsWithoutDecimalPrecisionError() {
        // Full 100/yr, intro 90.5/yr → exactly 9.5% off. Computing per-month by dividing each price
        // by 12 first would truncate the repeating decimals to 9.4999… and round DOWN to 9.
        // The single-division form keeps it exactly 9.5 → rounds to 10.
        let introOffer = IntroductoryOfferEntity(
            price: 90.5,
            period: .init(unit: .year, value: 1),
            periodCount: 1,
            paymentMode: .payUpFront
        )
        let plan = PlanEntity(
            type: .proI,
            subscriptionCycle: .yearly,
            appStorePrice: .init(price: 100, formattedPrice: "$100", currency: "USD"),
            introductoryOffer: introOffer
        )

        #expect(plan.introOfferDiscountPercentage == 10)
    }

    @Test
    func introOfferDiscountPercentage_whenFullPriceIsZero_shouldBeNil() {
        let introOffer = IntroductoryOfferEntity(
            price: 0,
            period: .init(unit: .year, value: 1),
            periodCount: 1
        )
        let plan = PlanEntity(
            type: .proI,
            subscriptionCycle: .yearly,
            appStorePrice: .init(price: 0, formattedPrice: "$0", currency: "USD"),
            introductoryOffer: introOffer
        )

        #expect(plan.introOfferDiscountPercentage == nil)
    }

    @Test
    func introOfferDiscountPercentage_whenTotalMonthsIsZero_shouldBeNil() {
        // periodCount 0 → totalMonths 0. Guard returns nil rather than dividing by zero.
        let introOffer = IntroductoryOfferEntity(
            price: 50,
            period: .init(unit: .year, value: 1),
            periodCount: 0
        )
        let plan = PlanEntity(
            type: .proI,
            subscriptionCycle: .yearly,
            appStorePrice: .init(price: 100, formattedPrice: "$100", currency: "USD"),
            introductoryOffer: introOffer
        )

        #expect(plan.introOfferDiscountPercentage == nil)
    }

    @Test
    func introOfferDiscountPercentage_whenWithoutIntroOffer_shouldBeNil() {
        let plan = PlanEntity(
            type: .proI,
            subscriptionCycle: .yearly,
            appStorePrice: .init(price: 100, formattedPrice: "$100", currency: "USD"),
            introductoryOffer: nil
        )

        #expect(plan.introOfferDiscountPercentage == nil)
    }
}
