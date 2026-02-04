import FirebaseCrashlytics
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
        MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Fetching latest subscription details...")
        CrashlyticsLogger.log(category: .storeKit, "Check subscription cancellation started - Fetching latest subscription details...")
        MEGASdk.sharedSdk.getSubscriptionCancellationDetails(
            withGateway: .itunes,
            originalTransactionId: nil,
            delegate: RequestDelegate { [weak self] result in
                Task(priority: .background) {
                    switch result {
                    case .success(let request) where request.isExpireOrCancelled:
                        MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Last subscription with id \(request.transactionId) is expired or cancelled - number: \(request.number) - numDetails: \(request.numDetails)")

                        CrashlyticsLogger.log(category: .storeKit, "Last subscription \(request.transactionId) is expired or cancelled - number: \(request.number) - numDetails: \(request.numDetails)")

                        await self?.fetchAndSubmitSyncedReceipt()
                    case .success(let request):
                        MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Last subscription with id \(request.transactionId) is not expired nor cancelled")
                    case .failure(let error) where error.type == .apiENoent:
                        MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] User does not have subscription through App Store. \(String(describing: error.errorDescription))")
                    case .failure(let error):
                        MEGALogError("[StoreKit - checkForExpiredOrCancellation] Error checking subscription cancellation: \(String(describing: error.errorDescription))")
                        Crashlytics.recordCheckCancellationError(
                            code: error.type.rawValue,
                            description: "Unexpected error when checking for cancellation details: \(error.localizedDescription)"
                        )
                    }
                }
            }
        )
    }

    private func fetchAndSubmitSyncedReceipt() async {
        MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Checking and sending App Store receipt to check for un-synced purchases")
        guard !isSubmittingReceipt else {
            MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Receipt syncing cancelled, already submitting receipt")
            CrashlyticsLogger.log(category: .storeKit, "Receipt syncing cancelled, already submitting receipt")
            return
        }

        MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Getting sync receipt...")

        if let localReceipt = await getLocalReceiptData() {
            do {
                try await submitReceipt(localReceipt)
            } catch {
                MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Failed to sync using local receipt, trying with remote receipt")
                await refreshReceiptAndSubmit()
            }
        } else {
            MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Could not read local receipt, trying with remote receipt")
            await refreshReceiptAndSubmit()
        }
    }

    private func refreshReceiptAndSubmit() async {
        guard FileManager.default.ubiquityIdentityToken != nil else {
            MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] iCloud not logged in, skipped fetching for latest receipt")
            return
        }
        await ReceiptRefresher().refreshReceipt()
        if let localReceipt = await getLocalReceiptData() {
            do {
                try await submitReceipt(localReceipt)
            } catch {
                guard let error = error as? MEGAError else {
                    Crashlytics.recordCheckCancellationError(code: -3, description: "Syncing receipt failed due to unexpected non-mega error: \(error.localizedDescription)")
                    return
                }

                if error.type != .apiEExpired {
                    Crashlytics.recordCheckCancellationError(
                        code: -2,
                        description: "Syncing receipt failed due to unexpected error: \(error.localizedDescription) - type: \(error.type)"
                    )
                }
            }
        } else {
            Crashlytics.recordCheckCancellationError(code: -1, description: "Receipt not found after refreshing receipt")
        }
    }

    private func submitReceipt(_ receipt: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Submitting sync receipt...")
            MEGASdk.shared.submitPurchase(
                .itunes,
                receipt: receipt,
                delegate: RequestDelegate { result in
                    switch result {
                    case .success:
                        MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Receipt synced successfully")
                        continuation.resume()
                    case .failure(let error):
                        MEGALogError("[StoreKit - checkForExpiredOrCancellation] Submitting receipt failed with error: \(String(describing: error.errorDescription))")
                        CrashlyticsLogger.log(category: .storeKit, "Submitting receipt failed with error: \(String(describing: error.errorDescription))")
                        continuation.resume(throwing: error)
                    }
                }
            )
        }
    }

    private func getLocalReceiptData() async -> String? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] App Store receipt URL is nil")
            CrashlyticsLogger.log(category: .storeKit, "App Store receipt URL is nil")
            return nil
        }

        do {
            return try Data(contentsOf: receiptURL).base64EncodedString()
        } catch {
            MEGALogDebug("[StoreKit - checkForExpiredOrCancellation] Unable to read App Store receipt data")
            // When appStoreReceiptURL is available but cannot be read, we fetch the latest receipt from AppStore and sync if possible
            CrashlyticsLogger.log(
                category: .storeKit,
                "Unable to read App Store receipt data from \(receiptURL.absoluteString) error: \(error.localizedDescription)"
            )
            return nil
        }
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
        MEGALogDebug("[StoreKit] Refreshing App Store receipt")
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
        MEGALogDebug("[StoreKit] Successfully refreshed App Store receipt")
        CrashlyticsLogger.log(category: .storeKit, "Successfully refreshed App Store receipt")
        continuation?.resume()
        $continuation.mutate { $0 = nil }
        $activeRequest.mutate { $0 = nil }
        request.cancel()
    }

    func request(_ request: SKRequest, didFailWithError error: any Error) {
        let error = error as NSError
        MEGALogError("[StoreKit] Could not refresh receipt with error: \(error.underlyingErrorDescription ?? "none") - error code: \(error.code)")
        CrashlyticsLogger.log(category: .storeKit, "Could not refresh receipt with error: \(error.underlyingErrorDescription ?? error.localizedDescription)")
        continuation?.resume()
        $continuation.mutate { $0 = nil }
        $activeRequest.mutate { $0 = nil }
        request.cancel()
    }
}

private extension NSError {
    var underlyingErrorDescription: String? {
        guard let error = userInfo["NSUnderlyingError"] as? NSError else { return nil }
        guard let innerError = error.userInfo["NSUnderlyingError"] as? NSError else { return error.localizedFailureReason }
        return innerError.localizedFailureReason
    }
}

private extension Crashlytics {
    static func recordCheckCancellationError(code: Int, description: String) {
        let error = NSError(
            domain: "nz.mega.storeKitCheckCancellation",
            code: code,
            userInfo: [NSLocalizedDescriptionKey: description]
        )
        Crashlytics.crashlytics().record(error: error)
    }
}
