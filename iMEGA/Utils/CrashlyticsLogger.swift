import FirebaseCrashlytics

final class CrashlyticsLogger {
    class func log(_ msg: String) {
        Crashlytics.crashlytics().log(msg)
    }
}
