import MEGAAppSDKRepo
import MEGASwift
import StoreKit

extension MEGAPurchase {
    // [AP-2132]
    // There are situation for some users where our BE has cancelled the subscriptions (e.g: payment card issues).
    // But from Appstore side, user is still actively subscribing/paying for the product.
    // As a results, they wouldn't receive the Pro benefit from the plan they paid for.
    // In order to resolve this, we need to get the latest purchase receipt and send it to BE for them to revalidate the receipt and
    // possibly re-enable user's Pro status.

    @objc func checkForExpiredOrCancellation() {

        Task(priority: .background) {
            MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Fetching latest subscription details...")
            MEGASdk.sharedSdk.getSubscriptionCancellationDetails(
                withGateway: .itunes,
                originalTransactionId: nil,
                delegate: RequestDelegate { [weak self] result in
                    switch result {
                    case .success(let request) where request.isExpireOrCancelled:
                        MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Last subscription with id \(request.transactionId) is expired or cancelled - number: \(request.number) - numDetails: \(request.numDetails)")
                        self?.submitSyncedReceipt()
                    case .success(let request):
                        MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Last subscription with id \(request.transactionId) is not expired nor cancelled")
                    case .failure(let error) where error.type == .apiENoent:
                        MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] User does not have subscription through App Store. \(String(describing: error.errorDescription))")
                    case .failure(let error):
                        MEGALogError("[StoreKit - checkForExpiredOrCancellation] Error checking subscription cancellation: \(String(describing: error.errorDescription))")
                    }
                }
            )
        }
    }

    private func submitSyncedReceipt(shouldRetryUponFailure: Bool = true) {
        MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Checking and sending App Store receipt to check for un-synced purchases")

        guard !isSubmittingReceipt else {
            MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Submit receipt cancelled, already submitting receipt")
            return
        }

        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] App Store receipt URL is nil")
            return
        }

        MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Getting receipt data from \(receiptURL)")

        guard let receiptData = try? Data(contentsOf: receiptURL) else {
            MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Unable to read App Store receipt data")
            return
        }

        MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Submitting sync receipt...")

        MEGASdk.shared.submitPurchase(
            .itunes,
            receipt: receiptData.base64EncodedString(),
            delegate: RequestDelegate { [weak self] result in
                switch result {
                case .success:
                    MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Receipt submitted successfully")
                case .failure(let error):
                    MEGALogError("[StoreKit - checkForExpiredOrCancellation] Submitting receipt failed with error: \(String(describing: error.errorDescription))")

                    // If the first sync attempt with local receipt fails, we try again with a refreshed receipt
                    if shouldRetryUponFailure {
                        Task(priority: .background) {
                            await ReceiptRefresher().refreshReceipt()
                            self?.submitSyncedReceipt(shouldRetryUponFailure: false)
                        }
                    }
                }
            }
        )
    }
}

private extension MEGARequest {

    var isExpireOrCancelled: Bool {
        Double(number) < Date().timeIntervalSince1970 || numDetails > 0
    }

    var transactionId: String {
        text ?? "nil"
    }
}

private class ReceiptRefresher: NSObject, SKRequestDelegate, @unchecked Sendable {

    @Atomic private var continuation: CheckedContinuation<Void, Never>?
    @Atomic private var activeRequest: SKReceiptRefreshRequest?

    func refreshReceipt() async {
        MEGALogDebug("Refreshing App Store receipt")
        await withCheckedContinuation { continuation in
            self.$continuation.mutate { $0 = continuation }

            Task { @MainActor in
                let request = SKReceiptRefreshRequest()
                self.$activeRequest.mutate { $0 = request }
                request.delegate = self
                request.start()
            }
        }
    }

    func requestDidFinish(_ request: SKRequest) {
        MEGALogDebug("Successfully refreshed App Store receipt")
        continuation?.resume()
        $continuation.mutate { $0 = nil }
        $activeRequest.mutate { $0 = nil }
    }

    func request(_ request: SKRequest, didFailWithError error: any Error) {
        let error = error as NSError
        MEGALogError("Could not refresh receipt with error: \(error.underlyingErrorDescription ?? "none")")
        continuation?.resume()
        $continuation.mutate { $0 = nil }
        $activeRequest.mutate { $0 = nil }
    }
}

private extension NSError {
    var underlyingErrorDescription: String? {
        guard let error = userInfo["NSUnderlyingError"] as? NSError else { return nil }
        guard let innerError = error.userInfo["NSUnderlyingError"] as? NSError else { return error.localizedFailureReason }
        return innerError.localizedFailureReason
    }
}
