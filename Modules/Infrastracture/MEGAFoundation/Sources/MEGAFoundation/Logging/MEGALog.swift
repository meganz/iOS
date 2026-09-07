import MEGASwift

public struct MEGALog: Sendable {
    public enum Level: Int, Sendable, CaseIterable {
        case fatal, error, warning, info, debug, max
    }

    public protocol MEGALogging: Sendable {
        func log(level: Level, message: String, filename: String, line: Int)
    }
    
    private static let shared = MEGALog()
    
    @Atomic
    private var loggers: [any MEGALogging] = []
    
    private func log(level: Level, message: String, filename: String = #file, line: Int = #line) {
        loggers.forEach {
            $0.log(level: level, message: message, filename: filename, line: line)
        }
    }
    
    public static func log(level: Level, message: String, filename: String = #file, line: Int = #line) {
        shared.log(level: level, message: message, filename: filename, line: line)
    }
    
    public static func register(loggers: [any MEGALogging]) {
        shared.$loggers.mutate {  $0 = loggers }
    }
}
