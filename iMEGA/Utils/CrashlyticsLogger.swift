import FirebaseCrashlytics

@objc final class CrashlyticsLogger: NSObject {
    @objc class func log(_ msg: String) {
        Crashlytics.crashlytics().log(msg)
    }
}
