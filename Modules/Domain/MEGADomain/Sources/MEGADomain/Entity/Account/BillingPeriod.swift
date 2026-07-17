/// The unit of a subscription billing period.
///
/// MEGA support monthly and yearly plan
public enum BillingPeriodUnit: Equatable, Sendable {
    case month
    case year

    /// The number of months in one unit (`.year` == 12).
    public var months: Int { self == .year ? 12 : 1 }
}

/// A length of time expressed as `value` x`unit` (e.g. 6 months, 1 year).
public struct BillingPeriod: Equatable, Sendable {
    public let unit: BillingPeriodUnit
    public let value: Int

    public init(unit: BillingPeriodUnit, value: Int) {
        self.unit = unit
        self.value = value
    }

    public var totalMonths: Int { unit.months * value }
}
