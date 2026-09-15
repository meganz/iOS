import FirebaseCrashlytics
import Foundation
import ViewedLinks

/// Logs a Viewed Links store failure to Crashlytics.
struct ViewedLinksCrashlyticsErrorReporter: ViewedLinksErrorReporting {
    func reportError(_ error: any Error) {
        Crashlytics.crashlytics().log("ViewedLinks store unreadable, continuing in memory: \(error)")
        Crashlytics.crashlytics().record(error: error)
    }
}
