public struct PlanEntity: Sendable {
    public let productIdentifier: String
    public var type: AccountTypeEntity
    public var name: String
    public var currency: String
    public var subscriptionCycle: SubscriptionCycleEntity
    public var storage: String
    public var transfer: String
    public var price: Double
    public var formattedPrice: String

    /// A formatted string representing the equivalent monthly price for a yearly plan.
    ///
    /// This value is calculated by dividing the yearly price by 12 and formatting it for display.
    /// It is not applicable to monthly plans. If the yearly price is unavailable or cannot be formatted,
    /// the value will be `nil`.
    ///
    /// Example:
    /// ```swift
    /// let price = formattedMonthlyPriceForYearlyPlan // "$4.99"
    /// ```
    ///
    /// - Note: This value is intended for display purposes only and is based on the yearly subscription price.
    public var formattedMonthlyPriceForYearlyPlan: String?

    public init(
        productIdentifier: String = "",
        type: AccountTypeEntity = .free,
        name: String = "",
        currency: String = "",
        subscriptionCycle: SubscriptionCycleEntity = .none,
        storage: String = "",
        transfer: String = "",
        price: Double = 0,
        formattedPrice: String = "",
        formattedMonthlyPriceForYearlyPlan: String? = nil
    ) {
        self.productIdentifier = productIdentifier
        self.type = type
        self.name = name
        self.currency = currency
        self.subscriptionCycle = subscriptionCycle
        self.storage = storage
        self.transfer = transfer
        self.price = price
        self.formattedPrice = formattedPrice
        self.formattedMonthlyPriceForYearlyPlan = formattedMonthlyPriceForYearlyPlan
    }
}

extension PlanEntity: Equatable {
    public static func == (lhs: PlanEntity, rhs: PlanEntity) -> Bool {
        lhs.type == rhs.type && lhs.subscriptionCycle == rhs.subscriptionCycle
    }
}

extension PlanEntity: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(subscriptionCycle)
    }
}
