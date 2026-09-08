import FirebaseCrashlytics

enum MEGAPurchaseLogger {
    enum MEGALogLevel {
        case debug, warning, error
    }
    static func logMessage(_ message: String, megaLogLevel: MEGALogLevel = .debug) {
        switch megaLogLevel {
        case .debug:
            MEGALogDebug("[StoreKit] \(message)")
        case .warning:
            MEGALogWarning("[StoreKit] \(message)")
        case .error:
            MEGALogError("[StoreKit] \(message)")
        }

        CrashlyticsLogger.log(
            category: .storeKit,
            message
        )
    }
}

extension MEGAPurchase {
    @objc func recordPurchaseError(_ error: any Error, promotionalOfferId: String?) {
        Crashlytics.crashlytics().record(
            error: error,
            userInfo: ["promotionalOfferId": promotionalOfferId ?? "none"]
        )
    }
}
