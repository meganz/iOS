import Foundation

public extension IntroductoryOfferEntity {
    /// The number of months represented by a single offer `period`.
    ///
    /// Week and day are approximations (1 month ≈ 4 weeks ≈ 30 days). They are not used by MEGA's
    /// production offers (which are monthly/yearly) and exist only for completeness.
    private var monthsPerPeriod: Decimal {
        switch period.unit {
        case .year: Decimal(period.value) * 12
        case .month: Decimal(period.value)
        case .week: Decimal(period.value) / 4
        case .day: Decimal(period.value) / 30
        }
    }

    /// The total number of months the introductory pricing applies for
    /// (`period` length × how many times it repeats).
    var totalMonths: Decimal {
        monthsPerPeriod * Decimal(periodCount)
    }

    /// The total amount the user pays across the whole introductory phase.
    ///
    /// `price` alone is not enough because its meaning depends on `paymentMode`:
    /// pay-as-you-go charges `price` once per period, whereas pay-up-front charges `price` a single time.
    var totalPrice: Decimal {
        switch paymentMode {
        case .freeTrial: 0
        case .payUpFront: price
        case .payAsYouGo: price * Decimal(periodCount)
        }
    }

    /// The equivalent price per month during the introductory phase.
    ///
    /// Correct regardless of the offer's `period.unit`, `period.value`, `periodCount` or `paymentMode`.
    var pricePerMonth: Decimal {
        guard totalMonths > 0 else { return totalPrice }
        return totalPrice / totalMonths
    }
}
