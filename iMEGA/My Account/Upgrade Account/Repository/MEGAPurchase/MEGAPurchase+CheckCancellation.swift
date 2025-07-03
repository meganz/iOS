import MEGAAppSDKRepo
import StoreKit

extension MEGAPurchase {
    func checkForCancellation() {
        MEGALogDebug("[StoreKit] Checking for subscription cancellation details")
        sdk.getSubscriptionCancellationDetails(
            withGateway: .itunes,
            originalTransactionId: nil,
            delegate: RequestDelegate { result in
                switch result {
                case .success(let request) where request.isLastSubscriptionCanceled:
                    MEGALogDebug("[StoreKit] Last subscription with id \(request.transactionId) is cancelled")

                    MEGALogDebug("[StoreKit] Restoring transaction to check for out-of-sync cancellations")
                    SKPaymentQueue.default().restoreCompletedTransactions()
                case .success(let request):
                    MEGALogDebug("[StoreKit] Last subscription with id \(request.transactionId) is not cancelled")
                case .failure(let error):
                    if case .apiENoent = error.type {
                        MEGALogDebug("[StoreKit] User does not have subscription through App Store")
                    }
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
