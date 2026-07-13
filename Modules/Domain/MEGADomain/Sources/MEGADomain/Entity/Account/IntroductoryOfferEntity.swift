import Foundation

public struct IntroductoryOfferEntity: Sendable {
    /// How the introductory `price` is charged. Mirrors StoreKit's `Product.SubscriptionOffer.PaymentMode`.
    ///
    /// This determines how to interpret `price`:
    /// - `.payAsYouGo`: `price` is charged once per `period`, `periodCount` times (per-period price).
    /// - `.payUpFront`: `price` is a single charge covering the whole offer span (total price).
    /// - `.freeTrial`: the offer is free (`price` is 0).
    public enum PaymentMode: Sendable {
        case payAsYouGo
        case payUpFront
        case freeTrial
    }

    public let price: Decimal

    public struct SubscriptionPeriod: Sendable {
        public enum Unit: Sendable {
            case day
            case week
            case month
            case year
        }

        /// The unit of time that this period represents.
        public let unit: IntroductoryOfferEntity.SubscriptionPeriod.Unit

        /// The number of units that the period represents.
        public let value: Int

        public init(unit: IntroductoryOfferEntity.SubscriptionPeriod.Unit, value: Int) {
            self.unit = unit
            self.value = value
        }
    }

    public let period: SubscriptionPeriod

    /// The number of periods this offer will renew for.
    public let periodCount: Int

    /// How the introductory `price` is charged.
    public let paymentMode: PaymentMode

    public init(price: Decimal, period: SubscriptionPeriod, periodCount: Int, paymentMode: PaymentMode) {
        self.price = price
        self.period = period
        self.periodCount = periodCount
        self.paymentMode = paymentMode
    }
}
