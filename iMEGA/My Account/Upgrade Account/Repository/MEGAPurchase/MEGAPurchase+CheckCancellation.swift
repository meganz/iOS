import MEGAAppSDKRepo
import StoreKit

extension MEGAPurchase {
    // [AP-2132]
    // There are situation for some users where our BE has cancelled the subscriptions (e.g: payment card issues).
    // But from Appstore side, user is still actively subscribing/paying for the product.
    // As a results, they wouldn't receive the Pro benefit from the plan they paid for.
    // In order to resolve this, we need to get the latest purchase receipt and send it to BE for them to revalidate the receipt and
    // possibly re-enable user's Pro status.

    @objc func checkForCancellation() {
        MEGALogDebug("[StoreKit] Checking for subscription cancellation details")
        Task(priority: .background) {
            MEGASdk.sharedSdk.getSubscriptionCancellationDetails(
                withGateway: .itunes,
                originalTransactionId: nil,
                delegate: RequestDelegate { [weak self] result in
                    switch result {
                    case .success(let request) where request.isLastSubscriptionCanceled:
                        MEGALogDebug("[StoreKit] Last subscription with id \(request.transactionId) is cancelled")

                        self?.submitSyncedReceipt()
                    case .success(let request):
                        MEGALogDebug("[StoreKit] Last subscription with id \(request.transactionId) is not cancelled")
                    case .failure(let error):
                        if case .apiENoent = error.type {
                            MEGALogDebug("[StoreKit] User does not have subscription through App Store")
                        } else {
                            MEGALogDebug("[StoreKit] Error checking subscription cancellation: \(error.localizedDescription)")
                        }
                    }
                }
            )
        }
    }

    private func submitSyncedReceipt() {
        MEGALogDebug("[StoreKit] Submitting App Store receipt to check for un-synced purchases")

        guard !isSubmittingReceipt else {
            MEGALogDebug("[StoreKit] Submit receipt cancelled, already submitting receipt")
            return
        }

        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            MEGALogError("[StoreKit] App Store receipt URL is nil")
            return
        }

        guard let receiptData = try? Data(contentsOf: receiptURL) else {
            MEGALogError("[StoreKit] Unable to read App Store receipt data")
            return
        }

        MEGASdk.shared.submitPurchase(
            .itunes,
            receipt: receiptData.base64EncodedString(),
            delegate: RequestDelegate { result in
                switch result {
                case .success:
                    MEGALogDebug("[StoreKit] Receipt submitted successfully")
                case .failure(let error):
                    MEGALogError("[StoreKit] Submitting receipt failed with error: \(error.localizedDescription)")
                }
            }
        )
    }
}

private extension MEGARequest {
    var isLastSubscriptionCanceled: Bool {
        numDetails > 0
    }

    var transactionId: String {
        text ?? "nil"
    }
}
