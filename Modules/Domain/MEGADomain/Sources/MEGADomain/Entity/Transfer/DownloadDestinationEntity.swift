import Foundation

/// The SDK distinguishes between file and folder destinations based on the local path format.
/// DownloadDestinationEntity lets callers explicitly specify the destination type, so the SDK path can be
/// constructed correctly and consistently in one place.
/// See DownloadDestinationEntity+Mapper for the SDK path-mapping rules.
public struct DownloadDestinationEntity: Sendable, Equatable {
    /// The folder holding the download, always a directory URL.
    public let folder: URL
    /// The file name to store. Pass `nil` to use node's name
    public let name: String?

    private init(folder: URL, name: String?) {
        self.folder = folder
        self.name = name
    }

    /// Stores the node inside `folder`, optionally under `name`
    public static func folder(_ folder: URL, name: String? = nil) -> Self {
        Self(folder: folder, name: name)
    }

    /// Stores the node at exactly `file`
    public static func file(_ file: URL) -> Self {
        Self(folder: file.deletingLastPathComponent(), name: file.lastPathComponent)
    }
}
