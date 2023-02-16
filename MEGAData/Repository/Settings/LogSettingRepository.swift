import MEGADomain

struct LogSettingRepository: LogSettingRepositoryProtocol {
    static var newRepo: LogSettingRepository {
        LogSettingRepository()
    }
    
    func toggleLogs(enable: Bool) {
        if enable {
            MEGALogger.shared()?.stopLogging()
            MEGAChatSdk.setLogObject(nil)
            Logger.shared().removeLogsDirectory()
        } else {
            MEGAChatSdk.setLogObject(Logger.shared())
            MEGALogger.shared()?.preparingForLogging()
        }
    }
}
