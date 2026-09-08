import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGARepo
import StoreKit

extension MEGAPurchase {
    enum PromotionalOfferResolutionError: Error {
        case subscriptionInfoNotAvailable
        case promotionalOfferNotAvailable
        case suppressedByIntroOffer
    }

    /// The promotional discount to attach to the payment for `product`.
    /// - Returns: The signed discount, ready to be set on the payment.
    /// - Throws:
    ///   ``subscriptionInfoNotAvailable`` when the App Store
    ///   returned no subscription information for the product, so nothing can be confirmed. Usually the
    ///   store was unreachable.
    ///
    ///   ``suppressedByIntroOffer`` when the customer can still redeem an
    ///   introductory offer, which takes precedence. In this case the caller submits the payment with no
    ///   discount attached and the App Store applies the introductory price at checkout.
    ///
    ///   ``promotionalOfferNotAvailable`` when the offer is absent from
    ///   the pricing, has expired, carries an incomplete signature, or is not listed against the product
    ///   in the App Store.
    func promotionalOffer(
        forProduct product: SKProduct,
        eligibility: some StoreKitSubscriptionEligibilityChecking = StoreKitSubscriptionEligibility(),
        subscriptionInfoProvider: some StoreKitSubscriptionInfoProviding = StoreKitSubscriptionInfoProvider(),
        requester: some PricingRequesting = PricingRequester.shared
    ) async throws(PromotionalOfferResolutionError) -> SKPaymentDiscount {
        let productIdentifier = product.productIdentifier
        guard let subscriptionInfo = await subscriptionInfoProvider.subscriptionInfo(forProductIdentifier: productIdentifier) else {
            MEGAPurchaseLogger.logMessage("No subscription information for product \"\(productIdentifier)\", aborting purchase", megaLogLevel: .error)
            throw .subscriptionInfoNotAvailable
        }

        // An existing, redeemable introductory offer suppresses the promotional offer, and the App Store applies its discount
        // at checkout automatically, so no promotional offer should be attached in that case.
        let activeGroupIDs = await eligibility.activeSubscriptionGroupIDs()
        MEGAPurchaseLogger.logMessage("Active subscription group IDs: \(activeGroupIDs)")
        if await eligibility.isIntroductoryOfferRedeemable(
            for: subscriptionInfo,
            activeGroupIDs: activeGroupIDs
        ) {
            MEGAPurchaseLogger.logMessage("Product \"\(productIdentifier)\" gets an introductory offer, which takes precedence over the promotional offer")
            throw .suppressedByIntroOffer
        }

        // According to Apple, a signature has a TTL of 24h, therefore
        // we should attempt to refresh Pricing to get the latest signature data
        do {
            try await requester.refreshPricing()
        } catch {
            MEGAPurchaseLogger.logMessage(
                "Could not refresh the pricing for \"\(productIdentifier)\", its offer signature may be stale: \(error)",
                megaLogLevel: .warning
            )
        }

        guard let mobileOffer = mobileOffer(for: product) else {
            MEGAPurchaseLogger.logMessage(
                "No offer in the pricing for product \"\(productIdentifier)\", aborting promotional offer",
                megaLogLevel: .warning
            )
            throw .promotionalOfferNotAvailable
        }

        // Need to guard against offer's expiryDate to avoid applying a promotional offer of a lapsed campaign.
        // Example: In Upgrade page, when a discount campaign has lapsed, the Upgrade page stops showing offers, but
        // MEGAPricing's existing offer may not be refresh thus the obsolete offer data still exists. In such case
        // we can check against `expiryDate` to prevent the offer from being wrongly applied.
        if let expiryDate = mobileOffer.expiryDate, expiryDate <= Date() {
            MEGAPurchaseLogger.logMessage("Expired promotional offer for product \"\(product.productIdentifier)\", aborting promotional offer", megaLogLevel: .warning)
            throw .promotionalOfferNotAvailable
        }

        guard let iosSignature = mobileOffer.iosSignature,
              !iosSignature.offerId.isEmpty,
              !iosSignature.keyId.isEmpty,
              !iosSignature.signature.isEmpty,
              let nonce = UUID(uuidString: iosSignature.nonce),
              iosSignature.timestamp > 0 else {
            MEGAPurchaseLogger.logMessage("Incomplete promotional offer for product \"\(product.productIdentifier)\", aborting promotional offer", megaLogLevel: .warning)
            throw .promotionalOfferNotAvailable
        }
        
        try await Self.checkOfferApplicable(
            subscription: subscriptionInfo,
            productIdentifier: productIdentifier,
            offerId: iosSignature.offerId
        )

        return SKPaymentDiscount(
            identifier: iosSignature.offerId,
            keyIdentifier: iosSignature.keyId,
            nonce: nonce,
            signature: iosSignature.signature,
            timestamp: NSNumber(value: iosSignature.timestamp)
        )
    }

    /// Whether the App Store will accept the promotional offer for a  product
    private static func checkOfferApplicable(
        subscription: Product.SubscriptionInfo,
        productIdentifier: String,
        offerId: String
    ) async throws(PromotionalOfferResolutionError) {
        guard subscription.promotionalOffers.contains(where: { $0.id == offerId }) else {
            MEGAPurchaseLogger.logMessage("Promotional offer \"\(offerId)\" is not listed against product \"\(productIdentifier)\", abandoning the purchase", megaLogLevel: .warning)
            throw .promotionalOfferNotAvailable
        }
    }
}
