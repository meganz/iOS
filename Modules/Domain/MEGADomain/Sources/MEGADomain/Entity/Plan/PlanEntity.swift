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
    public var transferLimit: Int
    public var storage: String
    public var transfer: String

    /// Only valid if API Price is supposed to be used
    public var apiPrice: PlanPriceEntity?
    public var appStorePrice: PlanPriceEntity

    // The introductory offer available to this plan, sourced from StoreKit
    // introductoryOffer is prioritize over promotionalOffer, when a plan carries
    // an intro offer, it overshadow its promo offer.
    public var introductoryOffer: SubscriptionOfferEntity?

    // The mobile offer available to this plan, sourced from API.
    public var mobileOffer: MobileOfferEntity?

    // The promotion offer available to this plan, sourced from StoreKit
    public var promotionalOffer: SubscriptionOfferEntity?

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

    public var formattedPriceForYearlyPlan: String? {
        subscriptionCycle == .yearly
            ? numberFormatter.string(for: price)
            : nil
    }

    public var mobileOfferLabel: String? {
        applicableOffer != nil ? mobileOffer?.label : nil
    }

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter
    }

    /// The discount percentage offered by the introductory offer compared to the full price.
    /// If there is no introductory offer, or if the full price is zero, this property returns `nil
    /// - Warning: This only produces the right value when the introductory offer is a 1-year pay-up-front
    ///   offer on a yearly plan. It compares the raw intro price against the raw full price, so it is
    ///   incorrect for any offer whose span differs from the billing cycle (multi-period, pay-as-you-go,
    ///   multi-unit). It survives only for the legacy Accounts upgrade screen. New code should resolve the
    ///   plan through `SubscriptionPlanPriceUseCase` and read `SubscriptionPlanPrice.discountPercentage`.
    public var introDiscountPercentage: Int? {
        guard let introductoryOffer else { return nil}
        let fullPrice = price
        let introPrice = introductoryOffer.price
        guard fullPrice > 0 else { return nil }
        let discountPercentage = ((fullPrice - introPrice) / fullPrice) * 100
        let discountPercentageRounded = NSDecimalNumber(decimal: discountPercentage).rounding(accordingToBehavior: nil).intValue
        return discountPercentageRounded
    }

    // A promotional offer is only valid (e.g: Can be shown to user and can be redeemed)
    // once it's available from StoreKit and its signature is also provided by API
    public var hasValidPromotionalOffer: Bool {
        promotionalOffer != nil && mobileOffer?.iosSignature != nil
    }

    public init(
        productIdentifier: String = "",
        type: AccountTypeEntity = .free,
        name: String = "",
        currency: String = "",
        subscriptionCycle: SubscriptionCycleEntity = .none,
        storageLimit: Int = 0,
        transferLimit: Int = 0,
        storage: String = "",
        transfer: String = "",
        price: Decimal = 0,
        formattedPrice: String = "",
        introductoryOffer: SubscriptionOfferEntity? = nil,
        mobileOffer: MobileOfferEntity? = nil,
        promotionalOffer: SubscriptionOfferEntity? = nil
    ) {
        self.productIdentifier = productIdentifier
        self.type = type
        self.name = name
        self.subscriptionCycle = subscriptionCycle
        self.storageLimit =  storageLimit
        self.transferLimit = transferLimit
        self.storage = storage
        self.transfer = transfer
        self.appStorePrice = PlanPriceEntity(
            price: price,
            formattedPrice: formattedPrice,
            currency: currency
        )
        self.introductoryOffer = introductoryOffer
        self.mobileOffer = mobileOffer
        self.promotionalOffer = promotionalOffer
    }

    public init(
        productIdentifier: String = "",
        type: AccountTypeEntity = .free,
        name: String = "",
        subscriptionCycle: SubscriptionCycleEntity = .none,
        storageLimit: Int = 0,
        transferLimit: Int = 0,
        apiPrice: PlanPriceEntity? = nil,
        appStorePrice: PlanPriceEntity = PlanPriceEntity(price: 0, formattedPrice: "", currency: ""),
        introductoryOffer: SubscriptionOfferEntity? = nil,
        mobileOffer: MobileOfferEntity? = nil,
        promotionalOffer: SubscriptionOfferEntity? = nil
    ) {
        self.productIdentifier = productIdentifier
        self.type = type
        self.name = name
        self.subscriptionCycle = subscriptionCycle
        self.storageLimit = storageLimit
        self.transferLimit = transferLimit
        self.storage = storageLimit.toGBString()
        self.transfer = transferLimit.toGBString()
        self.apiPrice = apiPrice
        self.appStorePrice = appStorePrice
        self.introductoryOffer = introductoryOffer
        self.mobileOffer = mobileOffer
        self.promotionalOffer = promotionalOffer
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
