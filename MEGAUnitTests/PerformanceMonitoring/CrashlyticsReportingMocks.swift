import FirebaseCrashlytics
@testable import MEGA

final class CrashlyticsReportingMocks: CrashlyticsReporting, @unchecked Sendable {
    var customValues: [String: Any] = [:]
    var reportedError: (any Error)?
    var reportedException: ExceptionModel?
    var reportedCount: Int = 0
    
    func setCustomValue(_ value: Any?, forKey key: String) {
        customValues[key] = value
    }
    
    func record(error: any Error) {
        reportedError = error
        reportedCount += 1
    }
    
    func record(exceptionModel: ExceptionModel) {
        reportedException = exceptionModel
        reportedCount += 1
    }
    
    func getIntValue(for key: String) -> Int? {
        return customValues[key] as? Int
    }
    
    func getStringValue(for key: String) -> String? {
        return customValues[key] as? String
    }
}
