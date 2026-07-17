import Foundation

/// How an offer is charged, mirroring StoreKit's payment modes.
/// Reference: https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions
public enum OfferBillingSchedule: Equatable, Sendable {
    /// Pay-as-you-go: `price` is charged once per `period`, repeated `periodCount` times.
    /// Example: 10$ per month for 6 months (price is 10, periodCount is 6 and period is (1, .month)
    case recurring(price: Decimal, period: BillingPeriod, periodCount: Int)
    /// Pay-up-front: `price` is a single charge covering the whole `period`.
    /// Example: 10$ for 6 months (price is 10 and period is (6, .month)
    case prepaid(price: Decimal, period: BillingPeriod)
    /// Free trial: no charge for the whole `period`.
    case free(period: BillingPeriod)

    /// Total duration of the offer, in months.
    public var totalMonths: Int {
        switch self {
        case let .recurring(_, period, periodCount): period.totalMonths * periodCount
        case let .prepaid(_, period): period.totalMonths
        case let .free(period): period.totalMonths
        }
    }

    /// Total amount paid over the entire offer period
    public var totalPrice: Decimal {
        switch self {
        case let .recurring(price, _, periodCount): price * Decimal(periodCount)
        case let .prepaid(price, _): price
        case .free: 0
        }
    }

    /// The offer price expressed per month.
    public var pricePerMonth: Decimal {
        guard totalMonths > 0 else { return totalPrice }
        return totalPrice / Decimal(totalMonths)
    }
}

/// The business-resolved pricing of a subscription plan, ready to be formatted for display.
public enum SubscriptionPlanPrice: Equatable, Sendable {
    case monthly(Monthly)
    case yearly(Yearly)
    case discountMonthly(DiscountMonthly)
    case discountYearly(DiscountYearly)
}

public extension SubscriptionPlanPrice {
    struct Monthly: Equatable, Sendable {
        /// The full monthly price.
        public let price: Decimal
        public let currency: String

        public init(price: Decimal, currency: String) {
            self.price = price
            self.currency = currency
        }
    }

    struct Yearly: Equatable, Sendable {
        /// The full yearly price.
        public let price: Decimal
        public let currency: String

        public init(price: Decimal, currency: String) {
            self.price = price
            self.currency = currency
        }
    }

    /// An offer applied on top of a base `Monthly` / `Yearly` price.
    struct Offer: Equatable, Sendable {
        /// The full price for the same offer period without the discount
        public let originalPrice: Decimal
        /// The discount as a whole percentage vs the full price, over the same span (0 if not cheaper).
        public let discountPercentage: Int
        public let schedule: OfferBillingSchedule

        public init(originalPrice: Decimal, discountPercentage: Int, schedule: OfferBillingSchedule) {
            self.originalPrice = originalPrice
            self.discountPercentage = discountPercentage
            self.schedule = schedule
        }
    }

    struct DiscountMonthly: Equatable, Sendable {
        public let monthly: Monthly
        public let offer: Offer

        public init(monthly: Monthly, offer: Offer) {
            self.monthly = monthly
            self.offer = offer
        }
    }

    struct DiscountYearly: Equatable, Sendable {
        public let yearly: Yearly
        public let offer: Offer

        public init(yearly: Yearly, offer: Offer) {
            self.yearly = yearly
            self.offer = offer
        }
    }

    /// The introductory discount as a whole percentage, or `nil` when this isn't a discount.
    var discountPercentage: Int? {
        switch self {
        case .monthly, .yearly: nil
        case let .discountMonthly(model): model.offer.discountPercentage
        case let .discountYearly(model): model.offer.discountPercentage
        }
    }
}
