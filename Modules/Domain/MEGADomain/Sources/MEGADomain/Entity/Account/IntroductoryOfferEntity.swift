import Foundation

public struct IntroductoryOfferEntity: Sendable {
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

    public init(price: Decimal, period: SubscriptionPeriod, periodCount: Int) {
        self.price = price
        self.period = period
        self.periodCount = periodCount
    }
}
