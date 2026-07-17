import Foundation
import MEGADomain
import MEGADomainMock
import Testing

/// Exercises the offer's derived pricing through `IntroductoryOfferEntity.billingSchedule`
/// (`OfferBillingSchedule` is the single source of truth for `totalMonths` / `totalPrice` / `pricePerMonth`).
struct IntroductoryOfferEntityPricingTests {

    // MARK: - totalMonths

    @Test(
        arguments: [
            // unit, value, periodCount, expectedMonths
            (BillingPeriodUnit.year, 1, 1, 12),
            (.year, 1, 2, 24),
            (.month, 1, 1, 1),
            (.month, 3, 1, 3),
            (.month, 1, 6, 6)
        ]
    )
    func totalMonths(
        unit: BillingPeriodUnit,
        value: Int,
        periodCount: Int,
        expected: Int
    ) {
        // Default payment mode is pay-as-you-go (`.recurring`), which folds `periodCount` into the span.
        let offer = IntroductoryOfferEntity(
            period: .init(unit: unit, value: value),
            periodCount: periodCount
        )
        #expect(offer.billingSchedule.totalMonths == expected)
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
        #expect(offer.billingSchedule.totalPrice == 30)
    }

    @Test
    func totalPrice_payAsYouGo_isPricePerPeriodTimesCount() {
        let offer = IntroductoryOfferEntity(
            price: 2,
            period: .init(unit: .month, value: 1),
            periodCount: 3,
            paymentMode: .payAsYouGo
        )
        #expect(offer.billingSchedule.totalPrice == 6)
    }

    @Test
    func totalPrice_freeTrial_isZero() {
        let offer = IntroductoryOfferEntity(
            price: 99,
            period: .init(unit: .month, value: 1),
            periodCount: 1,
            paymentMode: .freeTrial
        )
        #expect(offer.billingSchedule.totalPrice == 0)
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
        #expect(offer.billingSchedule.pricePerMonth == 10)
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
        #expect(offer.billingSchedule.pricePerMonth == 2)
    }

    @Test
    func pricePerMonth_multiMonthPeriod_dividesByPeriodValue() {
        // A 6-month period priced up front at 30 → 5/month.
        let offer = IntroductoryOfferEntity(
            price: 30,
            period: .init(unit: .month, value: 6),
            periodCount: 1,
            paymentMode: .payUpFront
        )
        #expect(offer.billingSchedule.pricePerMonth == 5)
    }

    @Test
    func pricePerMonth_freeTrial_isZero() {
        let offer = IntroductoryOfferEntity(
            price: 0,
            period: .init(unit: .month, value: 1),
            periodCount: 1,
            paymentMode: .freeTrial
        )
        #expect(offer.billingSchedule.pricePerMonth == 0)
    }

    @Test
    func pricePerMonth_whenTotalMonthsIsZero_fallsBackToTotalPriceWithoutDividingByZero() {
        // Zero-length period → totalMonths 0. pricePerMonth must not divide by zero.
        let offer = IntroductoryOfferEntity(
            price: 30,
            period: .init(unit: .month, value: 0),
            periodCount: 1,
            paymentMode: .payUpFront
        )
        let schedule = offer.billingSchedule
        #expect(schedule.totalMonths == 0)
        #expect(schedule.pricePerMonth == schedule.totalPrice)
    }
}
