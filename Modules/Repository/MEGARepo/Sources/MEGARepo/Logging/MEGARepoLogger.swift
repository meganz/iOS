import Foundation

/// App-injected logging hooks, mirroring the `Chat` module's pattern.
///
/// MEGARepo cannot call the SDK-backed `MEGALog*` functions itself: they live in
/// `MEGAAppSDKRepo`, which depends on this package, so the import would be a
/// dependency cycle. Instead the app wires these hooks to `MEGALog*` at startup
/// (see `AppDelegate.setupRepoLogging`) so MEGARepo messages keep landing in the
/// MEGA log file.
public enum MEGARepoLogger {
    public typealias LogFunction = @Sendable (_ message: String, _ file: String, _ line: Int) -> Void

    nonisolated(unsafe) public static var logError: LogFunction?
    nonisolated(unsafe) public static var logWarning: LogFunction?
    nonisolated(unsafe) public static var logDebug: LogFunction?
}

// Internal package-scoped counterparts of the app's SDK-backed MEGALog* functions,
// same pattern as ContentLibraries and MEGAInfrastructure, so call sites read
// identically to code living in the app target.
func MEGALogError(_ message: String, _ file: String = #file, _ line: Int = #line) {
    MEGARepoLogger.logError?(message, file, line)
}

func MEGALogWarning(_ message: String, _ file: String = #file, _ line: Int = #line) {
    MEGARepoLogger.logWarning?(message, file, line)
}

func MEGALogDebug(_ message: String, _ file: String = #file, _ line: Int = #line) {
    MEGARepoLogger.logDebug?(message, file, line)
}
