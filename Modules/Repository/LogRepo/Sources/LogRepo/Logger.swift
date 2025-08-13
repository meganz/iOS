@preconcurrency import CocoaLumberjackSwift
import Foundation
import MEGAChatSdk
import MEGASdk

@objc public final class Logger: NSObject, @unchecked Sendable {
    private let fileLogger: DDFileLogger
    
    @objc public let logsDirectoryUrl: URL
    
    @objc public class func shared() -> Logger {
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
        self.logsDirectoryUrl = URL(fileURLWithPath: fileLogger.logFileManager.logsDirectory)
    }
    
    @objc public func removeLogsDirectory( _ file: String = #file, _ line: Int = #line) {
        do {
            try FileManager.default.removeItem(at: logsDirectoryUrl)
        } catch {
            MEGASdk.log(with: .error, message: "[iOS] \(error.localizedDescription)", filename: file, line: line)
        }
    }
}

// MARK: - MEGALoggerDelegate

extension Logger: MEGALoggerDelegate {
    public func log(withTime time: String, logLevel: MEGALogLevel, source: String, message: String) {
        switch logLevel {
        case .fatal, .error:
            DDLogError(message.logMessageFormat)
        case .warning:
            DDLogWarn(message.logMessageFormat)
        case .info:
            DDLogInfo(message.logMessageFormat)
        case .debug:
            DDLogDebug(message.logMessageFormat)
        case .max:
            DDLogVerbose(message.logMessageFormat)
        default:
            DDLogVerbose(message.logMessageFormat)
        }
    }
}

// MARK: - MEGAChatLoggerDelegate

extension Logger: MEGAChatLoggerDelegate {
    public func log(with logLevel: MEGAChatLogLevel, message: String) {
        switch logLevel {
        case .fatal, .error:
            DDLogError(message.logMessageFormat)
        case .warning:
            DDLogWarn(message.logMessageFormat)
        case .info:
            DDLogInfo(message.logMessageFormat)
        case .debug:
            DDLogDebug(message.logMessageFormat)
        case .verbose, .max:
            DDLogVerbose(message.logMessageFormat)
        default:
            DDLogVerbose(message.logMessageFormat)
        }
    }
}

private extension String {
    var logMessageFormat: DDLogMessageFormat {
        DDLogMessageFormat(stringLiteral: self)
    }
}
