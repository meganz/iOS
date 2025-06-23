import Foundation

public struct PlanPriceEntity: Sendable {
    public var price: Decimal
    public var formattedPrice: String
    public var currency: String

    public init(price: Decimal, formattedPrice: String, currency: String) {
        self.price = price
        self.formattedPrice = formattedPrice
        self.currency = currency
    }
}

public struct PlanEntity: Sendable {
    public let productIdentifier: String
    public var type: AccountTypeEntity
    public var name: String
    public var subscriptionCycle: SubscriptionCycleEntity
    public var storage: String
    public var transfer: String

    /// Only valid if API Price is supposed to be used
    public var apiPrice: PlanPriceEntity?
    public var appStorePrice: PlanPriceEntity

    public var price: Decimal { apiPrice?.price ?? appStorePrice.price}
    public var formattedPrice: String { apiPrice?.formattedPrice ?? appStorePrice.formattedPrice }
    public var currency: String { apiPrice?.currency ?? appStorePrice.currency }

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
        let monthlyPrice: Decimal = price / 12

        return subscriptionCycle == .yearly
            ? numberFormatter.string(for: monthlyPrice)
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
        price: Decimal = 0,
        formattedPrice: String = ""
    ) {
        self.productIdentifier = productIdentifier
        self.type = type
        self.name = name
        self.subscriptionCycle = subscriptionCycle
        self.storage = storage
        self.transfer = transfer
        self.appStorePrice = PlanPriceEntity(
            price: price,
            formattedPrice: formattedPrice,
            currency: currency
        )
    }

    public init(
        productIdentifier: String = "",
        type: AccountTypeEntity = .free,
        name: String = "",
        subscriptionCycle: SubscriptionCycleEntity = .none,
        storage: String = "",
        transfer: String = "",
        apiPrice: PlanPriceEntity? = nil,
        appStorePrice: PlanPriceEntity = PlanPriceEntity(price: 0, formattedPrice: "", currency: "")
    ) {
        self.productIdentifier = productIdentifier
        self.type = type
        self.name = name
        self.subscriptionCycle = subscriptionCycle
        self.storage = storage
        self.transfer = transfer
        self.apiPrice = apiPrice
        self.appStorePrice = appStorePrice
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
