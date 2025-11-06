import Foundation

public typealias LogFunction = (_ message: String, _ file: String, _ line: Int) -> Void

public struct Chat {
    nonisolated(unsafe) public static var logFatal: LogFunction?
    nonisolated(unsafe) public static var logError: LogFunction?
    nonisolated(unsafe) public static var logWarning: LogFunction?
    nonisolated(unsafe) public static var logInfo: LogFunction?
    nonisolated(unsafe) public static var logDebug: LogFunction?
    nonisolated(unsafe) public static var logMax: LogFunction?
    
    static func logger(level: LogLevel) -> LogFunction? {
        switch level {
        case .fatal:
            logFatal
        case .error:
            logError
        case .warning:
            logWarning
        case .info:
            logInfo
        case .debug:
            logDebug
        case .max:
            logMax
        }
    }
}

enum LogLevel {
    case fatal
    case error
    case warning
    case info
    case debug
    case max
}

func log(level: LogLevel, _ message: String, _ file: String = #file, _ line: Int = #line) {
    if let logger = Chat.logger(level: level) {
        logger(message, file, line)
    } else {
        print("\(message)")
    }
}

func logFatal(_ message: String, _ file: String = #file, _ line: Int = #line) {
    log(level: .fatal, message, file, line)
}

func logError(_ message: String, _ file: String = #file, _ line: Int = #line) {
    log(level: .error, message, file, line)
}

func logWarning(_ message: String, _ file: String = #file, _ line: Int = #line) {
    log(level: .warning, message, file, line)
}

func logInfo(_ message: String, _ file: String = #file, _ line: Int = #line) {
    log(level: .info, message, file, line)
}

func logDebug(_ message: String, _ file: String = #file, _ line: Int = #line) {
    log(level: .debug, message, file, line)
}

func logMax(_ message: String, _ file: String = #file, _ line: Int = #line) {
    log(level: .max, message, file, line)
}
