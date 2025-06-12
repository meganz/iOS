import Foundation

public struct PlanEntity: Sendable {
    public let productIdentifier: String
    public var type: AccountTypeEntity
    public var name: String
    public var subscriptionCycle: SubscriptionCycleEntity
    public var storage: String
    public var transfer: String

    public var useAPIPrice: Bool
    public var apiPrice: Double?
    public var apiFormattedPrice: String?
    public var apiCurrency: String?
    public var appStorePrice: Double
    public var appStoreFormattedPrice: String
    public var appStoreCurrency: String

    public var price: Double { useAPIPrice ? (apiPrice ?? 0) : appStorePrice }
    public var formattedPrice: String { useAPIPrice ? (apiFormattedPrice ?? "") : appStoreFormattedPrice }
    public var currency: String { useAPIPrice ? (apiCurrency ?? "") : appStoreCurrency }

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
    public var formattedMonthlyPriceForYearlyPlan: String? {
        subscriptionCycle == .yearly
            ? numberFormatter.string(for: Int(ceil(self.price / 12.0)))
            : nil
    }

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter
    }

    public init(
        productIdentifier: String = "",
        type: AccountTypeEntity = .free,
        name: String = "",
        currency: String = "",
        subscriptionCycle: SubscriptionCycleEntity = .none,
        storage: String = "",
        transfer: String = "",
        price: Double = 0,
        formattedPrice: String = ""
    ) {
        self.productIdentifier = productIdentifier
        self.type = type
        self.name = name
        self.subscriptionCycle = subscriptionCycle
        self.storage = storage
        self.transfer = transfer
        self.appStorePrice = price
        self.appStoreFormattedPrice = formattedPrice
        self.appStoreCurrency = currency
        self.useAPIPrice = false
    }

    public init(
        productIdentifier: String = "",
        type: AccountTypeEntity = .free,
        name: String = "",
        subscriptionCycle: SubscriptionCycleEntity = .none,
        storage: String = "",
        transfer: String = "",
        apiPrice: Double = 0.0,
        apiFormattedPrice: String? = nil,
        apiCurrency: String = "",
        appStorePrice: Double = 0.0,
        appStoreFormattedPrice: String = "",
        appStoreCurrency: String = "",
        useAPIPrice: Bool = false
    ) {
        self.productIdentifier = productIdentifier
        self.type = type
        self.name = name
        self.subscriptionCycle = subscriptionCycle
        self.storage = storage
        self.transfer = transfer
        self.apiPrice = apiPrice
        self.apiFormattedPrice = apiFormattedPrice
        self.apiCurrency = apiCurrency
        self.appStorePrice = appStorePrice
        self.appStoreFormattedPrice = appStoreFormattedPrice
        self.appStoreCurrency = appStoreCurrency
        self.useAPIPrice = useAPIPrice
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
