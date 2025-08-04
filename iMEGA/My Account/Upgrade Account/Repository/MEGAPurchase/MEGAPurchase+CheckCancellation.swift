import MEGAAppSDKRepo
import StoreKit

extension MEGAPurchase {
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

                        self?.submitReceipt()
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

    private func submitReceipt() {
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

        MEGASdk.shared.submitPurchase(.itunes, receipt: receiptData.base64EncodedString(), delegate: self)
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
