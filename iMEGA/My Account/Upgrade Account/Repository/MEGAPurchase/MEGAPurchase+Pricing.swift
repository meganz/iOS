import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGASdk
import StoreKit

extension MEGAPurchase {
    func requestPricingAsync() async {
        guard products == nil || products.isEmpty else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            _ = DelegateHolder(purchase: self, continuation: continuation)
            self.requestPricing()
        }
    }

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
        guard let pricing, let index = productIndex(for: product, in: pricing),
              pricing.toMobileOfferEntity(index: index)?.iosSignature != nil else {
            return true
        }

        let refreshedPricing: MEGAPricing? = await withCheckedContinuation { continuation in
            MEGASdk.shared.getPricingWith(RequestDelegate { result in
                switch result {
                case .success(let request):
                    continuation.resume(returning: request.pricing)
                case .failure(let error):
                    CrashlyticsLogger.log(category: .storeKit, "Could not refresh MEGAPricing for promotional offer. Error: \(error.type) - \(error.name)")
                    MEGALogError("[StoreKit] Failed to refresh the promotional offer before purchase")
                    continuation.resume(returning: nil)
                }
            })
        }

        guard let refreshedPricing else { return false }
        await MainActor.run { self.pricing = refreshedPricing }
        return true
    }

    private func promotionalOffer(for product: SKProduct) -> SKPaymentDiscount? {
        guard let pricing, let index = productIndex(for: product, in: pricing),
              let iosSignature = pricing.toMobileOfferEntity(index: index)?.iosSignature else { return nil }

        guard !iosSignature.offerId.isEmpty, !iosSignature.keyId.isEmpty, !iosSignature.signature.isEmpty,
              let nonce = UUID(uuidString: iosSignature.nonce), iosSignature.timestamp > 0 else {
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
    private func productIndex(for product: SKProduct, in pricing: MEGAPricing) -> Int? {
        for index in 0..<pricing.products where pricing.iOSID(atProductIndex: index) == product.productIdentifier {
            return index
        }
        return nil
    }

    private final class DelegateHolder: NSObject, MEGAPurchasePricingDelegate {
        let continuation: CheckedContinuation<Void, Never>
        let purchase: MEGAPurchase

        init(purchase: MEGAPurchase, continuation: CheckedContinuation<Void, Never>) {
            self.purchase = purchase
            self.continuation = continuation
            super.init()
            purchase.addPricingsDelegate(self)
        }

        func pricingsReady() {
            continuation.resume()
            purchase.removePricingsDelegate(self)
        }
    }
}
