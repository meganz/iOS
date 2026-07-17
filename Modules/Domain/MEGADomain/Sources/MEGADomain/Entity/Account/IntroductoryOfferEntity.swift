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

    /// One billing cycle of the offer (mirrors StoreKit's `Product.SubscriptionPeriod`)
    public let period: BillingPeriod

    /// The number of periods this offer will renew for.
    public let periodCount: Int

    /// How the introductory `price` is charged.
    public let paymentMode: PaymentMode

    public init(price: Decimal, period: BillingPeriod, periodCount: Int, paymentMode: PaymentMode) {
        self.price = price
        self.period = period
        self.periodCount = periodCount
        self.paymentMode = paymentMode
    }
}
