import FileProvider
import Foundation
import MEGADomain

/// A node as it appears in the File Provider domain: the cloud drive root is `.rootContainer` and the rubbish bin
/// is `.trashContainer`, so a node directly in the rubbish bin has `.trashContainer` as its parent.
public struct FileProviderItemEntity: Sendable, Equatable {
    public let identifier: NSFileProviderItemIdentifier
    public let parentIdentifier: NSFileProviderItemIdentifier
    public let node: NodeEntity
    /// How many children a folder has, or `nil` for a file.
    public let childCount: Int?

    public init(
        identifier: NSFileProviderItemIdentifier,
        parentIdentifier: NSFileProviderItemIdentifier,
        node: NodeEntity,
        childCount: Int? = nil
    ) {
        self.identifier = identifier
        self.parentIdentifier = parentIdentifier
        self.node = node
        self.childCount = childCount
    }
}

// MARK: - Versions

public extension FileProviderItemEntity {
    /// Changes only when the file's bytes do; the system uses it to tell whether a local copy is out of date.
    ///
    /// Both versions are compared across processes and launches, so they are built from node attributes only and
    /// never from `hashValue`, which is seeded per process.
    var contentVersion: Data {
        guard node.isFile else {
            // A folder has no contents of its own: its children are enumerated.
            return Data("folder".utf8)
        }
        if let fingerprint = node.fingerprint, !fingerprint.isEmpty {
            return Data(fingerprint.utf8)
        }
        return Self.encode(["\(node.size)", "\(Self.seconds(node.modificationTime))"])
    }

    /// Changes whenever an attribute Files shows does: the name, the location, including a move to or from the
    /// trash, the modification date or a folder's child count.
    var metadataVersion: Data {
        Self.encode([
            node.name,
            parentIdentifier.rawValue,
            "\(Self.seconds(node.modificationTime))",
            childCount.map { "\($0)" } ?? ""
        ])
    }

    private static func seconds(_ date: Date) -> Int64 {
        Int64(date.timeIntervalSince1970)
    }

    /// Joined with a separator that cannot appear in a node name, so two different sets of values never encode
    /// to the same data.
    private static func encode(_ values: [String]) -> Data {
        Data(values.joined(separator: "\u{0}").utf8)
    }
}
