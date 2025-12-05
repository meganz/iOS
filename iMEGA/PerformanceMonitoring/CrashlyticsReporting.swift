import FirebaseCrashlytics

public protocol CrashlyticsReporting: Sendable {
    func setCustomValue(_ value: Any?, forKey key: String)
    func record(error: any Error)
    func record(exceptionModel: ExceptionModel)
}

extension Crashlytics: CrashlyticsReporting {}
