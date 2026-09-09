import FirebaseCrashlytics
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAFoundation

enum MEGAPurchaseLogger {
    enum MEGALogLevel {
        case debug, warning, error
    }
    static func logMessage(
        _ message: String,
        megaLogLevel: MEGALogLevel = .debug,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let megaLogMessage = "[StoreKit] \(message)"
        switch megaLogLevel {
        case .debug:
            MEGALog.log(level: .debug, message: megaLogMessage, filename: file, line: line)
        case .warning:
            MEGALog.log(level: .warning, message: megaLogMessage, filename: file, line: line)
        case .error:
            MEGALog.log(level: .error, message: message, filename: file, line: line)
        }

        CrashlyticsLogger.log(
            category: .storeKit,
            message,
            file,
            function
        )
    }
}

extension MEGAPurchase {
    @objc func recordPurchaseError(_ error: any Error, promotionalOfferId: String?) {
        Crashlytics.crashlytics().record(
            error: error,
            userInfo: ["promotionalOfferId": promotionalOfferId ?? "none"]
        )

        DIContainer.tracker.trackAnalyticsEvent(
            with: UpgradePlansPurchaseErrorEvent(details: (error as NSError).purchaseFailureDescription)
        )
    }
}

private extension NSError {

    /// Maximum number of error to walk down the underlying error chain to keep the tracked string compact.
    static let maximumErrorCount = 5

    /// The description of the error, consists of its own error domain and code every underlying error below it, flattened to one line.
    /// Example: `SKErrorDomain:0 > ASDErrorDomain:504 > AMSErrorDomain:305 (Verification Required)`.
    var purchaseFailureDescription: String {
        var descriptions = [String]()
        var pending = [self]

        while !pending.isEmpty, descriptions.count < Self.maximumErrorCount {
            let error = pending.removeFirst()
            descriptions.append(error.domainCodeAndMessage)
            pending.append(contentsOf: error.underlyingErrors.map { $0 as NSError })
        }

        return descriptions.joined(separator: " > ")
    }

    var domainCodeAndMessage: String {
        guard let message = failureMessage else { return "\(domain):\(code)" }
        return "\(domain):\(code) (\(message))"
    }

    var failureMessage: String? {
        [NSLocalizedFailureReasonErrorKey, NSLocalizedDescriptionKey, NSDebugDescriptionErrorKey]
            .compactMap { userInfo[$0] as? String }
            .first { !$0.isEmpty }
    }
}
