import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGARepo
import MEGASdk
import StoreKit

extension MEGAPurchase {
    @objc func submitPayment(forProduct product: SKProduct) {
        Task { @MainActor in
            guard await shouldApplyPromotionalOffer(forProduct: product) else {
                addPayment(forProduct: product, promotionalOffer: nil)
                return
            }

            await submitPaymentWithPromotionalOffer(forProduct: product)
        }
    }

    /// Whether the purchase should try to attach a promotional offer: the product has to carry a signed one
    /// and the customer has to be able to redeem it.
    func shouldApplyPromotionalOffer(
        forProduct product: SKProduct,
        eligibility: some StoreKitSubscriptionEligibilityChecking = StoreKitSubscriptionEligibility()
    ) async -> Bool {
        let productIdentifier = product.productIdentifier

        guard mobileOffer(for: product)?.iosSignature != nil else {
            MEGAPurchaseLogger.logMessage("Product \"\(productIdentifier)\" carries no signed promotional offer, purchasing without promotional offer")
            return false
        }

        guard await eligibility.canRedeemPromotionalOffer() else {
            MEGAPurchaseLogger.logMessage(
                "Customer cannot redeem a promotional offer, purchasing \"\(productIdentifier)\" without promotional offer",
                megaLogLevel: .warning
            )
            return false
        }

        return true
    }

    @MainActor private func submitPaymentWithPromotionalOffer(forProduct product: SKProduct) async {
        do throws(PromotionalOfferResolutionError) {
            MEGAPurchaseLogger.logMessage("Resolving promotional offer for \(product.productIdentifier)")
            let discount = try await promotionalOffer(forProduct: product)
            MEGAPurchaseLogger.logMessage("Successfully resolved promotional offer for \(product.productIdentifier)")
            addPayment(forProduct: product, promotionalOffer: discount)
        } catch {
            switch error {
            case .suppressedByIntroOffer:
                // When intro offer is available and redeemable, we don't attach the promotional offer,
                // StoreKit will automatically apply the intro offer at checkout
                MEGAPurchaseLogger.logMessage("Skipping the promotional offer for \(product.productIdentifier): \(error)")
                addPayment(forProduct: product, promotionalOffer: nil)
            case .subscriptionInfoNotAvailable, .promotionalOfferNotAvailable:
                MEGAPurchaseLogger.logMessage(
                    "Could not resolve the promotional offer for \(product.productIdentifier): \(error)",
                    megaLogLevel: .warning
                )
                abortPurchaseForPromotionalOfferError(forProduct: product, error: error)
            }
        }
    }

    @MainActor private func abortPurchaseForPromotionalOfferError(forProduct product: SKProduct, error: any Error) {
        MEGAPurchaseLogger.logMessage("Aborting the purchase of \"\(product.productIdentifier)\": its promotional offer could not be resolved, so it must not be charged at full price", megaLogLevel: .error)

        recordPurchaseError(error, promotionalOfferId: nil)
        SVProgressHUD.dismiss()
        SVProgressHUD.setDefaultMaskType(.none)



        let promotionalOfferUnavailable = AccountPlanErrorEntity.promotionalOfferUnavailableError
        for delegate in purchaseDelegates {
            delegate.failedPurchase?(promotionalOfferUnavailable.errorCode, message: promotionalOfferUnavailable.errorMessage)
        }

        // User may reach this point from promoted plan purchase flow
        // In that case we need to end that flow accordingly 
        if isPurchasingPromotedPlan {
            setIsPurchasingPromotedPlan(false)
            handlePromotedPlanPurchaseResult(isSuccess: false)
        }
    }

    private func addPayment(forProduct product: SKProduct, promotionalOffer: SKPaymentDiscount?) {
        let paymentRequest = SKMutablePayment(product: product)
        paymentRequest.applicationUsername = MEGASdk.base64Handle(forUserHandle: MEGASdk.currentUserHandle()?.uint64Value ?? 0) ?? ""

        if let promotionalOffer {
            MEGAPurchaseLogger.logMessage("Applying promotional offer \"\(promotionalOffer.identifier)\" to product \"\(product.productIdentifier)\"")
            paymentRequest.paymentDiscount = promotionalOffer
            // BE signs the promotional offer signature with "" applicationUsername so we need to
            // match that in order for the signature to work
            paymentRequest.applicationUsername = ""
        } else {
            MEGAPurchaseLogger.logMessage("Applying no promotional offer to product \"\(product.productIdentifier)\"")
        }

        SKPaymentQueue.default().add(paymentRequest)
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
