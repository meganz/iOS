import Foundation

@objc public class CameraUploadTaskIdentifierOCWrapper: NSObject {
    /// Returns the local identifier from the task description if it can be parsed.
    /// If the task description is not in the expected (chunk) format, it falls back
    /// to using the raw description string. This ensures backwards compatibility
    /// when tasks are restored after an app update.
    @objc public static func localIdentifier(from taskDescription: String?) -> String? {
        taskDescription.localIdentifier()
    }
}
