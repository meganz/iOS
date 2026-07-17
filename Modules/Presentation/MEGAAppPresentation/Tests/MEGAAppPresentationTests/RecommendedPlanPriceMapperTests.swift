import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAUIComponent
import Testing

@Suite("RecommendedPlanPriceMapper")
struct RecommendedPlanPriceMapperTests {
    // Locale pinned so € rendering + separators are deterministic regardless of the test host.
    private let sut = RecommendedPlanPriceMapper(locale: Locale(identifier: "en_US"))

    private func dec(_ value: String) -> Decimal { Decimal(string: value)! }

    // MARK: - Plain layouts

    @Test func monthly_rendersPricePerMonth() {
        let result = sut.map(.monthly(.init(price: dec("9.99"), currency: "EUR")))
        #expect(result == .monthly(.init(pricePerMonth: "€9.99/month")))
    }

    @Test func yearly_rendersPerMonthAndChargedYearly() {
        let result = sut.map(.yearly(.init(price: dec("40.01"), currency: "EUR")))
        #expect(result == .yearly(.init(
            pricePerMonth: "€3.33/month",
            billingCaption: "€40.01 charged yearly"
        )))
    }

    // MARK: - Discount monthly

    @Test func discountMonthly_prepaid_rendersTotalForMonths() {
        let result = sut.map(.discountMonthly(.init(
            monthly: .init(price: dec("9.99"), currency: "EUR"),
            offer: .init(
                originalPrice: dec("59.94"),
                discountPercentage: 50,
                schedule: .prepaid(price: dec("29.94"), period: .init(unit: .month, value: 6))
            )
        )))
        #expect(result == .discountMonthly(.init(
            originalPrice: "€59.94",
            discountedPrice: "€29.94 for 6 months",
            billingCaption: "Billed at €29.94 for the first 6 months, €9.99/month after"
        )))
    }

    @Test func discountMonthly_recurring_rendersPerMonthForMonths() {
        let result = sut.map(.discountMonthly(.init(
            monthly: .init(price: dec("9.99"), currency: "EUR"),
            offer: .init(
                originalPrice: dec("9.99"),
                discountPercentage: 50,
                schedule: .recurring(price: dec("4.99"), period: .init(unit: .month, value: 1), periodCount: 6)
            )
        )))
        #expect(result == .discountMonthly(.init(
            originalPrice: "€9.99",
            discountedPrice: "€4.99/month",
            billingCaption: "Billed at €4.99/month for the first 6 months, €9.99/month after"
        )))
    }

    @Test func discountMonthly_free_rendersZeroForMonths() {
        let result = sut.map(.discountMonthly(.init(
            monthly: .init(price: dec("9.99"), currency: "EUR"),
            offer: .init(
                originalPrice: dec("9.99"),
                discountPercentage: 100,
                schedule: .free(period: .init(unit: .month, value: 1))
            )
        )))
        #expect(result == .discountMonthly(.init(
            originalPrice: "€9.99",
            discountedPrice: "€0.00 for 1 month",
            billingCaption: "Billed at €0.00 for the first 1 month, €9.99/month after"
        )))
    }

    // MARK: - Discount yearly

    @Test func discountYearly_oneYear_rendersPerYear() {
        let result = sut.map(.discountYearly(.init(
            yearly: .init(price: dec("120"), currency: "EUR"),
            offer: .init(
                originalPrice: dec("120"),
                discountPercentage: 50,
                schedule: .prepaid(price: dec("59.88"), period: .init(unit: .year, value: 1))
            )
        )))
        #expect(result == .discountYearly(.init(
            pricePerMonth: "€4.99/month",
            originalPrice: "€120.00",
            discountedPrice: "€59.88 for 1 year",
            billingCaption: "Billed at €59.88 for the first year, €120.00 charged yearly after"
        )))
    }

    @Test func discountYearly_sixMonths_rendersForMonths() {
        let result = sut.map(.discountYearly(.init(
            yearly: .init(price: dec("119.88"), currency: "EUR"),
            offer: .init(
                originalPrice: dec("59.94"),
                discountPercentage: 50,
                schedule: .prepaid(price: dec("29.94"), period: .init(unit: .month, value: 6))
            )
        )))
        #expect(result == .discountYearly(.init(
            pricePerMonth: "€4.99/month",
            originalPrice: "€59.94",
            discountedPrice: "€29.94 for 6 months",
            billingCaption: "Billed at €29.94 for the first 6 months, €119.88 charged yearly after"
        )))
    }

    // MARK: - Floor rounding of per-month figures (IOS-12214)

    @Test func perMonthFigures_areFlooredNotRoundedUp() {
        // 9.996 must display as €9.99 (floor), never €10.00.
        let result = sut.map(.monthly(.init(price: dec("9.996"), currency: "EUR")))
        #expect(result == .monthly(.init(pricePerMonth: "€9.99/month")))
    }
}
