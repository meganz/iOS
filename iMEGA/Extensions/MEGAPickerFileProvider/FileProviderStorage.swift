import FileProvider
import Foundation

/// Where a node's content lives inside the File Provider storage container, and the guards that keep it there.
///
/// A node's path comes from `Node::displaypath`, which joins every ancestor's name raw, and a cloud name is
/// arbitrary. A name of `..` in the leaf or in any ancestor makes the path resolve somewhere else: outside the
/// container, or onto another node's location inside it (`mail:Shared/../x` lands where the user's own `/x`
/// lives). Appended to `documentStorageURL` and then read or written, that turned a placeholder, a download or
/// an existence check into a create/read at a location the attacker chose, and let their item be mistaken for
/// the user's file. Every place that builds a local URL from a node path goes through here so both are refused
/// in one spot.
enum FileProviderStorage {
    /// The local URL for `nodePath` under `storageURL`, or `nil` when the path holds a `.` or `..` segment or
    /// would resolve outside the container. A legitimate node path never holds such a segment, so refusing it
    /// changes nothing for real content.
    static func contentURL(forNodePath nodePath: String, in storageURL: URL) -> URL? {
        guard !hasRelativeSegment(nodePath) else { return nil }
        let candidate = storageURL.appendingPathComponent(nodePath)
        return isContained(candidate, in: storageURL) ? candidate : nil
    }

    /// Whether any `/`-separated segment of `nodePath` is `.` or `..`. Checked on the raw path, before the file
    /// system gets to resolve those segments to some other location.
    static func hasRelativeSegment(_ nodePath: String) -> Bool {
        nodePath.split(separator: "/", omittingEmptySubsequences: true).contains { $0 == "." || $0 == ".." }
    }

    /// Whether `url`, with `.` and `..` resolved, is `base` itself or something under it. Compared through
    /// `fileProviderStoragePath` so a `/private` prefix on only one side does not change the answer.
    static func isContained(_ url: URL, in base: URL) -> Bool {
        let normalizedBase = base.path.fileProviderStoragePath
        let normalizedURL = url.path.fileProviderStoragePath
        return normalizedURL == normalizedBase || normalizedURL.hasPrefix(normalizedBase + "/")
    }
}
