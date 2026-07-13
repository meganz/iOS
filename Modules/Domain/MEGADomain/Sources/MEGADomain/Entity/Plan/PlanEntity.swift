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

    public var introductoryOffer: IntroductoryOfferEntity?
    public var mobileOfferLabel: String?

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

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter
    }

    /// The discount percentage offered by the introductory offer compared to the full price.
    /// If there is no introductory offer, or if the full price is zero, this property returns `nil
    /// - Warning: This is deprecated, please  use introOfferDiscountPercentage instead,
    ///   which compares intro vs full price over the same billing span and supports all introductory offer shapes.
    ///   This only produces the right value when the introductory offer is a 1-year pay-up-front offer on a yearly plan.
    ///   It compares the raw intro price against the raw full price, so it is incorrect
    ///   for any offer whose span differs from the billing cycle (multi-period, pay-as-you-go, multi-unit).
    ///   New code must use ``introOfferDiscountPercentage``.
    public var introDiscountPercentage: Int? {
        guard let introductoryOffer else { return nil}
        let fullPrice = price
        let introPrice = introductoryOffer.price
        guard fullPrice > 0 else { return nil }
        let discountPercentage = ((fullPrice - introPrice) / fullPrice) * 100
        let discountPercentageRounded = NSDecimalNumber(decimal: discountPercentage).rounding(accordingToBehavior: nil).intValue
        return discountPercentageRounded
    }

    /// The introductory-offer discount percentage, computed over the same billing span as the plan so
    /// it is correct for any offer shape (pay-as-you-go, pay-up-front, free trial, multi-unit / multi-period).
    ///
    /// Returns `nil` when there is no offer, the full price is zero, or the offer has no duration.
    public var introOfferDiscountPercentage: Int? {
        guard let introductoryOffer,
              price > 0,
              introductoryOffer.totalMonths > 0 else { return nil }

        // Discount = 1 - introPricePerMonth / fullPricePerMonth.
        //
        // We divide only once, at the end to avoid issue caused by Repeating-decimal rounding.
        // Notice the yearly case multiplies the intro price by 12
        // rather than dividing the full price by 12 — same result, but it avoids an early divide.
        // Why it matters: `Decimal` holds a limited number of digits, so dividing by 12 early gives a
        // repeating value (e.g. 8.3333…) that gets cut off, and that rounding error can bump the final
        // percentage to the wrong whole number.
        //
        // Example — yearly plan, full 100/yr, intro 90.5/yr (1-year offer, so totalMonths = 12):
        //   Dividing first: fullPerMonth = 100/12 = 8.3333…, introPerMonth = 90.5/12 = 7.5416…
        //                   (1 - 7.5416…/8.3333…) * 100 = 9.4999… → rounds DOWN to 9 ❌
        //   This form:      (1 - (12 * 90.5) / (12 * 100)) * 100 = (1 - 1086/1200) * 100
        //                   = 9.5 exactly → rounds to 10 ✅
        let discountPercentage: Decimal
        switch subscriptionCycle {
        case .none:
            return nil
        case .monthly:
            discountPercentage = (1 - introductoryOffer.totalPrice / (introductoryOffer.totalMonths * price)) * 100
        case .yearly:
            discountPercentage = (1 - (12 * introductoryOffer.totalPrice) / (introductoryOffer.totalMonths * price)) * 100
        }
        return NSDecimalNumber(decimal: discountPercentage).rounding(accordingToBehavior: nil).intValue
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
        introductoryOffer: IntroductoryOfferEntity? = nil,
        mobileOfferLabel: String? = nil
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
        self.mobileOfferLabel = mobileOfferLabel
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
        introductoryOffer: IntroductoryOfferEntity? = nil,
        mobileOfferLabel: String? = nil
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
        self.mobileOfferLabel = mobileOfferLabel
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
