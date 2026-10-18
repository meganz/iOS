import FileProvider
import Foundation

/// Where a node's content lives inside the File Provider storage container, and the guard that keeps it there.
///
/// A node's path comes from `Node::displaypath`, which joins every ancestor's name raw, and a cloud name is
/// arbitrary: a name of `..` in the leaf or in any ancestor makes the path resolve outside the container.
/// Appended to `documentStorageURL` and then read or written, that turned a placeholder, a download or an
/// existence check into an arbitrary create/read anywhere in the shared app-group container. Every place that
/// builds a local URL from a node path goes through here so the traversal is refused in one spot.
enum FileProviderStorage {
    /// The local URL for `nodePath` under `storageURL`, or `nil` when the path would resolve outside it.
    static func contentURL(forNodePath nodePath: String, in storageURL: URL) -> URL? {
        let candidate = storageURL.appendingPathComponent(nodePath)
        return isContained(candidate, in: storageURL) ? candidate : nil
    }

    /// Whether `url`, with `.` and `..` resolved, is `base` itself or something under it. Compared through
    /// `fileProviderStoragePath` so a `/private` prefix on only one side does not change the answer.
    static func isContained(_ url: URL, in base: URL) -> Bool {
        let normalizedBase = base.path.fileProviderStoragePath
        let normalizedURL = url.path.fileProviderStoragePath
        return normalizedURL == normalizedBase || normalizedURL.hasPrefix(normalizedBase + "/")
    }
}
