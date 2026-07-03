import Foundation

/// Error surfaced while copying the SDK databases from the main app's App Group into an extension's
/// own Application Support. `step` identifies which stage of the copy pipeline failed, `fileName` is
/// set when the failure is tied to a specific file, and `underlyingError` carries the original error
/// for logging.
///
/// Marked `@unchecked Sendable` because the wrapped `underlyingError` values are `FileManager`
/// `NSError`s, which are effectively immutable and safe to hand across concurrency domains.
public enum CopyDataBasesErrorEntity: Error, @unchecked Sendable {
    public enum Step: Sendable {
        case applicationSupportDirectory
        case groupSupportDirectory
        case directoryContents
        case modificationDate
        case removeContents
        case copyContents
    }

    case fileManager(step: Step, fileName: String?, underlyingError: (any Error)?)
}
