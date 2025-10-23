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
    public var storageLimit: Int
    public var storage: String
    public var transfer: String

    /// Only valid if API Price is supposed to be used
    public var apiPrice: PlanPriceEntity?
    public var appStorePrice: PlanPriceEntity

    public var introductoryOffer: IntroductoryOfferEntity?

    public var price: Decimal { appStorePrice.price }
    public var formattedPrice: String { appStorePrice.formattedPrice }
    public var currency: String { appStorePrice.currency }

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

    /// The discount percentage offered by the introductory offer compared to the full price.
    /// If there is no introductory offer, or if the full price is zero, this property returns `nil
    /// /// Example:
    /// ```swift
    /// let discount = introDiscountPercentage // 20
    /// ```
    public var introDiscountPercentage: Int? {
        guard let introductoryOffer else { return nil}
        let fullPrice = price
        let introPrice = introductoryOffer.price
        guard fullPrice > 0 else { return nil }
        let discountPercentage = ((fullPrice - introPrice) / fullPrice) * 100
        let discountPercentageRounded = NSDecimalNumber(decimal: discountPercentage).rounding(accordingToBehavior: nil).intValue
        return discountPercentageRounded
    }

    public init(
        productIdentifier: String = "",
        type: AccountTypeEntity = .free,
        name: String = "",
        currency: String = "",
        subscriptionCycle: SubscriptionCycleEntity = .none,
        storageLimit: Int = 0,
        storage: String = "",
        transfer: String = "",
        price: Decimal = 0,
        formattedPrice: String = "",
        introductoryOffer: IntroductoryOfferEntity? = nil
    ) {
        self.productIdentifier = productIdentifier
        self.type = type
        self.name = name
        self.subscriptionCycle = subscriptionCycle
        self.storageLimit =  storageLimit
        self.storage = storage
        self.transfer = transfer
        self.appStorePrice = PlanPriceEntity(
            price: price,
            formattedPrice: formattedPrice,
            currency: currency
        )
        self.introductoryOffer = introductoryOffer
    }

    public init(
        productIdentifier: String = "",
        type: AccountTypeEntity = .free,
        name: String = "",
        subscriptionCycle: SubscriptionCycleEntity = .none,
        storageLimit: Int = 0,
        storage: String = "",
        transfer: String = "",
        apiPrice: PlanPriceEntity? = nil,
        appStorePrice: PlanPriceEntity = PlanPriceEntity(price: 0, formattedPrice: "", currency: ""),
        introductoryOffer: IntroductoryOfferEntity? = nil
    ) {
        self.productIdentifier = productIdentifier
        self.type = type
        self.name = name
        self.subscriptionCycle = subscriptionCycle
        self.storageLimit = storageLimit
        self.storage = storage
        self.transfer = transfer
        self.apiPrice = apiPrice
        self.appStorePrice = appStorePrice
        self.introductoryOffer = introductoryOffer
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
