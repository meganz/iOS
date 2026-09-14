import FirebaseCrashlytics
import Foundation
import ViewedLinks

/// Logs an unrecoverable Viewed Links store failure to Crashlytics and terminates the app.
struct ViewedLinksCrashlyticsErrorReporter: ViewedLinksErrorReporting {
    func reportFatalError(_ error: any Error) -> Never {
        Crashlytics.crashlytics().log("Aborting app due to ViewedLinks store error \(error)")
        Crashlytics.crashlytics().record(error: error)
        exit(0)
    }
}
