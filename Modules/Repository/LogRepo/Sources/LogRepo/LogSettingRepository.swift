import MEGAChatSdk
import MEGADomain

public struct LogSettingRepository: LogSettingRepositoryProtocol {
    public static var newRepo: LogSettingRepository {
        LogSettingRepository()
    }
    
    public func toggleLogs(enable: Bool, with logMetadata: LogMetadataEntity) {
        if enable {
            AppLogger(logMetadata: logMetadata).stop()
            MEGAChatSdk.setLogObject(nil)
            Logger.shared().removeLogsDirectory()
        } else {
            MEGAChatSdk.setLogObject(Logger.shared())
            AppLogger(logMetadata: logMetadata).prepare()
        }
    }
}
