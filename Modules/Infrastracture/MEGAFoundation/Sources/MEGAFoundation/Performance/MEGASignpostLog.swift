#if DEBUG
import Foundation
import os

public struct MEGASignpostLog {
    private var osLog: OSLog
     
    /// A constant string that produces a human-readable log message.
    private let formatString: StaticString = "Key:%{public}@,Value:%{public}@,Concept:%{public}@"
     
    // MARK: - Init
     
    public init(subsystem: String, category: String) {
        osLog = OSLog(subsystem: subsystem, category: category)
    }
     
    // MARK: - Public
     
    /// Logs a point of interest in your code as an event for debugging performance in Instruments,
    /// and includes a detailed message.
    public func event(name: StaticString = "Event", key: String, value: String, concept: MEGAEventConcept = .debug) {
        os_signpost(.event, log: osLog, name: name, formatString, key, value, concept.rawValue)
    }
     
    /// A signpost with pre-defined format that marks the start of a time interval of interest in your code.
    public func begin(name: StaticString = "Begin", key: String, value: String, concept: MEGAEventConcept = .debug) -> OSSignpostID {
        let id = signpostID()
         
        os_signpost(.begin, log: osLog, name: name, signpostID: id, formatString, key, value, concept.rawValue)
        return id
    }
     
    /// A signpost with pre-defined format that marks the end of a time interval of interest in your code.
    public func end(name: StaticString = "End", key: String, value: String, concept: MEGAEventConcept = .debug, id: OSSignpostID) {
        os_signpost(.end, log: osLog, name: name, signpostID: id, formatString, key, value, concept.rawValue)
    }
     
    /// Logs a point of interest in your code as a time interval for debugging performance in Instruments,
    /// and includes a detailed message.
    public func interval<T>(name: StaticString = "Interval",
                            key: String,
                            value: String,
                            concept: MEGAEventConcept = .debug, completion: () throws -> T) rethrows -> T {
        let id = begin(name: name, key: key, value: value, concept: concept)
         
        defer { end(name: name, key: key, value: value, concept: concept, id: id)}
        return try completion()
    }
     
    /// A signpost with customized format that marks the start of a time interval of interest in your code.
    public func begin(name: StaticString = "Begin", format: StaticString, arguments: [any CVarArg]) -> OSSignpostID {
        let id = signpostID()
         
        signpost(type: .begin, name: name, signpostID: id, format: format, args: arguments)
        return id
    }
     
    /// A signpost with customized format that marks the end of a time interval of interest in your code.
    public func end(name: StaticString = "End", id: OSSignpostID, format: StaticString, arguments: [any CVarArg]) {
        signpost(type: .end, name: name, signpostID: id, format: format, args: arguments)
    }
     
    // MARK: Private
     
    private func signpostID() -> OSSignpostID {
        return OSSignpostID(log: osLog)
    }
     
    /// Logs performance-related events using signposts with the `os_signpost` function.
    ///
    /// - Parameters:
    ///  - type: The type of the signpost event. Choose from `.begin`, `.end`, or `.event`.
    ///  - name: A descriptive name for the signpost event. This should be a static string.
    ///  - signpostID: An identifier for the signpost event.
    ///  - format: A static string that specifies the format of the log message.
    ///  - args: An array of `CVarArg` values representing the arguments to be included in the log message.
    ///
    /// - Note:
    ///   This function allows you to log performance data using signposts with a flexible number of arguments.
    ///   Depending on the number of arguments provided, it formats and logs the data accordingly.
    ///   If there are more than three arguments, an assertion failure is triggered,
    ///   and the data is logged with the first three arguments.
    private func signpost(type: OSSignpostType, name: StaticString, signpostID: OSSignpostID, format: StaticString, args: [any CVarArg]) {
        switch args.count {
        case 0:
            os_signpost(type, log: osLog, name: name, signpostID: signpostID)
        case 1:
            os_signpost(type, log: osLog, name: name, signpostID: signpostID, format, args[0])
        case 2:
            os_signpost(type, log: osLog, name: name, signpostID: signpostID, format, args[0], args[1])
        case 3:
            os_signpost(type, log: osLog, name: name, signpostID: signpostID, format, args[0], args[1], args[2])
        default:
            assertionFailure("Too many arguments passed to signpost.")
            os_signpost(type, log: osLog, name: name, signpostID: signpostID, format, args[0], args[1], args[2])
        }
    }
}
#endif
