import Foundation
import MEGADomain
import MEGADomainMock
import Testing

struct IntroductoryOfferEntityPricingTests {

    // MARK: - totalMonths

    @Test(
        arguments: [
            // unit, value, periodCount, expectedMonths
            (IntroductoryOfferEntity.SubscriptionPeriod.Unit.year, 1, 1, Decimal(12)),
            (.year, 1, 2, Decimal(24)),
            (.month, 1, 1, Decimal(1)),
            (.month, 3, 1, Decimal(3)),
            (.month, 1, 6, Decimal(6)),
            (.week, 1, 1, Decimal(0.25)),
            (.day, 1, 1, Decimal(1) / Decimal(30))
        ]
    )
    func totalMonths(
        unit: IntroductoryOfferEntity.SubscriptionPeriod.Unit,
        value: Int,
        periodCount: Int,
        expected: Decimal
    ) {
        let offer = IntroductoryOfferEntity(
            period: .init(unit: unit, value: value),
            periodCount: periodCount
        )
        #expect(offer.totalMonths == expected)
    }

    // MARK: - totalPrice (depends on paymentMode)

    @Test
    func totalPrice_payUpFront_isTheSingleCharge() {
        let offer = IntroductoryOfferEntity(
            price: 30,
            period: .init(unit: .month, value: 6),
            periodCount: 1,
            paymentMode: .payUpFront
        )
        #expect(offer.totalPrice == 30)
    }

    @Test
    func totalPrice_payAsYouGo_isPricePerPeriodTimesCount() {
        let offer = IntroductoryOfferEntity(
            price: 2,
            period: .init(unit: .month, value: 1),
            periodCount: 3,
            paymentMode: .payAsYouGo
        )
        #expect(offer.totalPrice == 6)
    }

    @Test
    func totalPrice_freeTrial_isZero() {
        let offer = IntroductoryOfferEntity(
            price: 99,
            period: .init(unit: .month, value: 1),
            periodCount: 1,
            paymentMode: .freeTrial
        )
        #expect(offer.totalPrice == 0)
    }

    // MARK: - pricePerMonth

    @Test
    func pricePerMonth_yearlyPayUpFront_dividesByTwelve() {
        let offer = IntroductoryOfferEntity(
            price: 120,
            period: .init(unit: .year, value: 1),
            periodCount: 1,
            paymentMode: .payUpFront
        )
        #expect(offer.pricePerMonth == 10)
    }

    @Test
    func pricePerMonth_payAsYouGoMonthly_isThePerPeriodPrice() {
        let offer = IntroductoryOfferEntity(
            price: 2,
            period: .init(unit: .month, value: 1),
            periodCount: 3,
            paymentMode: .payAsYouGo
        )
        // 3 months at 2 each → 2/month
        #expect(offer.pricePerMonth == 2)
    }

    @Test
    func pricePerMonth_multiMonthPeriod_dividesByPeriodValue() {
        // A 6-month period priced up front at 30 → 5/month.
        // (The old logic ignored period.value and would have reported 30/month.)
        let offer = IntroductoryOfferEntity(
            price: 30,
            period: .init(unit: .month, value: 6),
            periodCount: 1,
            paymentMode: .payUpFront
        )
        #expect(offer.pricePerMonth == 5)
    }

    @Test
    func pricePerMonth_freeTrial_isZero() {
        let offer = IntroductoryOfferEntity(
            price: 0,
            period: .init(unit: .month, value: 1),
            periodCount: 1,
            paymentMode: .freeTrial
        )
        #expect(offer.pricePerMonth == 0)
    }

    @Test
    func pricePerMonth_whenTotalMonthsIsZero_fallsBackToTotalPriceWithoutDividingByZero() {
        // periodCount 0 → totalMonths 0. pricePerMonth must not divide by zero.
        let offer = IntroductoryOfferEntity(
            price: 30,
            period: .init(unit: .month, value: 3),
            periodCount: 0,
            paymentMode: .payUpFront
        )
        #expect(offer.totalMonths == 0)
        #expect(offer.pricePerMonth == offer.totalPrice)
    }
}
