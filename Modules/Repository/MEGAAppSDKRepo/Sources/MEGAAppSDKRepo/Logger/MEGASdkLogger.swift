import MEGAFoundation
import MEGASdk
import MEGASwift

public struct MEGASdkLogger: MEGALog.MEGALogging {
    public init() {}

    public func log(level: MEGALog.Level, message: String, filename: String, line: Int) {
        MEGASdk.log(
            with: MEGALogLevel(rawValue: level.rawValue) ?? .max,
            message: "[iOS] [\(filename.lastPathComponent):\(line)] \(message)",
            filename: filename,
            line: line
        )
    }
}
