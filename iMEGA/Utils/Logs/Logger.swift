import CocoaLumberjackSwift
import Foundation

@objc final class Logger: NSObject {
    private let fileLogger: DDFileLogger
    
    @objc lazy var logsDirectoryUrl = URL(fileURLWithPath: fileLogger.logFileManager.logsDirectory)
    
    @objc class func shared() -> Logger {
        return sharedLogger
    }
    
    private static let sharedLogger: Logger = {
        DDLog.add(DDOSLogger.sharedInstance)
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folderURL = documentDirectory.appendingPathComponent("MEGAiOS/Logs")
        let manager = DDLogFileManagerDefault(logsDirectory: folderURL.path)
        let fileLogger = DDFileLogger(logFileManager: manager)
        fileLogger.rollingFrequency = 0
        fileLogger.logFileManager.maximumNumberOfLogFiles = 20
        fileLogger.maximumFileSize = 10 * 1024 * 1024 // 10 MB
        fileLogger.logFileManager.logFilesDiskQuota = 200 * 1024 * 1024 // 200 MB
        fileLogger.logFormatter = CustomDDLogFormatter()
        DDLog.add(fileLogger)
        return Logger(fileLogger: fileLogger)
    }()
    
    private init(fileLogger: DDFileLogger) {
        self.fileLogger = fileLogger
    }
    
    @objc func removeLogsDirectory() {
        do {
            try FileManager.default.removeItem(at: logsDirectoryUrl)
        } catch {
            MEGALogError(error.localizedDescription)
        }
    }
}

// MARK: - MEGALoggerDelegate

extension Logger: MEGALoggerDelegate {
    func log(withTime time: String, logLevel: MEGALogLevel, source: String, message: String) {
        switch logLevel {
        case .fatal, .error:
            DDLogError(message)
        case .warning:
            DDLogWarn(message)
        case .info:
            DDLogInfo(message)
        case .debug:
            DDLogDebug(message)
        case .max:
            DDLogVerbose(message)
        default:
            DDLogVerbose(message)
        }
    }
}

// MARK: - MEGAChatLoggerDelegate

extension Logger: MEGAChatLoggerDelegate {
    func log(with logLevel: MEGAChatLogLevel, message: String) {
        switch logLevel {
        case .fatal, .error:
            DDLogError(message)
        case .warning:
            DDLogWarn(message)
        case .info:
            DDLogInfo(message)
        case .debug:
            DDLogDebug(message)
        case .verbose, .max:
            DDLogVerbose(message)
        default:
            DDLogVerbose(message)
        }
    }
}
