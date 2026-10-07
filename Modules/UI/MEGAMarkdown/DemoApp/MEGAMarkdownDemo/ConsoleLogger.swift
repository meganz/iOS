import Foundation
import MEGAFoundation

/// Prints the package logs, so they show in the Xcode console. The MEGA app registers its own loggers.
struct ConsoleLogger: MEGALog.MEGALogging {
    func log(level: MEGALog.Level, message: String, filename: String, line: Int) {
        print("[\(level)] \((filename as NSString).lastPathComponent):\(line) \(message)")
    }
}
