import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGASdk
import StoreKit

extension MEGAPurchase {
    @objc func addPayment(forProduct product: SKProduct, applyPromotionalOffer: Bool) {
        let paymentRequest = SKMutablePayment(product: product)
        paymentRequest.applicationUsername = MEGASdk.base64Handle(forUserHandle: MEGASdk.currentUserHandle()?.uint64Value ?? 0) ?? ""

        if applyPromotionalOffer, let promotionalOffer = promotionalOffer(for: product) {
            MEGALogDebug("[StoreKit] Applying promotional offer \"\(promotionalOffer.identifier)\" to product \"\(product.productIdentifier)\"")
            paymentRequest.paymentDiscount = promotionalOffer
            // BE signs the promotional offer signature with "" applicationUsername so we need to
            // match that in order for the signature to work
            paymentRequest.applicationUsername = ""
        }

        SKPaymentQueue.default().add(paymentRequest)
    }

    /// Always refreshes pricing before purchasing a product that carries a promotional offer, so
    /// StoreKit receives a freshly signed offer.
    /// - Returns: `true` if the product has no promotional offer to refresh, or if the pricing was refreshed successfully;
    ///            `false` if the refresh failed and the pricing could not be updated.
    /// Discussion: According to Apple's documentation, a promotional offer's signature is only valid for ~24h. Therefore it's recommended to get a new signature for each purchase.
    @objc func refreshPricing(forProduct product: SKProduct) async -> Bool {
        await refreshPricing(forProduct: product, requester: PricingRequester.shared)
    }

    /// The injectable form of `refreshPricing(forProduct:)`. Production always goes through the shared
    /// requester; the parameter only exists so tests can drive the refresh without the singleton.
    func refreshPricing(forProduct product: SKProduct, requester: some PricingRequesting) async -> Bool {
        guard mobileOffer(for: product)?.iosSignature != nil else { return true }

        do {
            try await requester.refreshPricing()
            // IOS-12264: Handle signature refresh failure
            return true
        } catch {
            MEGALogError("[MEGAPurchase] Failed to refresh the promotional offer before purchase \(error)")
            return false
        }
    }

    private func promotionalOffer(for product: SKProduct) -> SKPaymentDiscount? {
        guard let mobileOffer = mobileOffer(for: product) else { return nil }

        // Need to guard against offer's expiryDate to avoid applying a promotional offer of a lapsed campaign.
        // Example: In Upgrade page, when a discount campaign has lapsed, the Upgrade page stops showing offers, but
        // MEGAPricing's existing offer may not be refresh thus the obsolete offer data still exists. In such case
        // we can check against `expiryDate` to prevent the offer from being wrongly applied.
        if let expiryDate = mobileOffer.expiryDate, expiryDate <= Date() {
            MEGALogWarning("[StoreKit] Expired promotional offer for product \"\(product.productIdentifier)\", purchasing without discount")
            return nil
        }

        guard let iosSignature = mobileOffer.iosSignature else { return nil }
        guard !iosSignature.offerId.isEmpty,
              !iosSignature.keyId.isEmpty,
              !iosSignature.signature.isEmpty,
              let nonce = UUID(uuidString: iosSignature.nonce),
              iosSignature.timestamp > 0 else {
            MEGALogWarning("[StoreKit] Incomplete promotional offer for product \"\(product.productIdentifier)\", purchasing without discount")
            return nil
        }

        return SKPaymentDiscount(
            identifier: iosSignature.offerId,
            keyIdentifier: iosSignature.keyId,
            nonce: nonce,
            signature: iosSignature.signature,
            timestamp: NSNumber(value: iosSignature.timestamp)
        )
    }

    /// Resolves the product's index against the given pricing directly, so the offer fields are
    /// always read from the same MEGAPricing (avoids desync with a separately cached index).
    func productIndex(for product: SKProduct) -> Int? {
        guard let pricing else { return nil }
        for index in 0..<pricing.products where pricing.iOSID(atProductIndex: index) == product.productIdentifier {
            return index
        }
        return nil
    }

    /// The offer attached to the pricing entry that matches this product, or `nil` when the product is
    /// not in the pricing or carries no offer.
    func mobileOffer(for product: SKProduct) -> MobileOfferEntity? {
        guard let pricing, let index = productIndex(for: product) else { return nil }
        return pricing.toMobileOfferEntity(index: index)
    }
}
