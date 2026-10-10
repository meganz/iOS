import FileProvider
import Foundation

/// An entry of the change queue: an item the system may hold an outdated copy of, and the folder it was seen in.
///
/// It records nothing about what changed; the item's current state is read when the change is delivered.
public struct FileProviderChangeEntity: Sendable, Hashable {
    public let identifier: NSFileProviderItemIdentifier
    /// The folder the item was seen in, or found missing from. It may no longer be the item's parent.
    public let folderIdentifier: NSFileProviderItemIdentifier

    public init(identifier: NSFileProviderItemIdentifier, folderIdentifier: NSFileProviderItemIdentifier) {
        self.identifier = identifier
        self.folderIdentifier = folderIdentifier
    }
}

/// A run of consecutive changes read from the change queue.
public struct FileProviderChangeBatchEntity: Sendable, Equatable {
    public let changes: [FileProviderChangeEntity]
    /// The position just after the last change in `changes`.
    public let nextAnchor: FileProviderChangeAnchorEntity
    /// Whether more changes follow `nextAnchor`.
    public let hasMore: Bool

    public init(changes: [FileProviderChangeEntity], nextAnchor: FileProviderChangeAnchorEntity, hasMore: Bool) {
        self.changes = changes
        self.nextAnchor = nextAnchor
        self.hasMore = hasMore
    }
}

public enum FileProviderChangeQueueErrorEntity: Error, Sendable, Equatable {
    /// The queue no longer has the changes after the anchor.
    case anchorExpired
}

/// A position in the change queue. It is the working set's sync anchor: everything before it has been delivered.
public struct FileProviderChangeAnchorEntity: Sendable, Equatable, Codable {
    /// Identifies the queue's storage. Storage created anew gets a new one, which expires every older anchor.
    public let storeID: UUID
    /// The queue file the position is in.
    public let generation: Int
    /// The byte offset in that file, always at the start of a line.
    public let offset: Int

    public init(storeID: UUID, generation: Int, offset: Int) {
        self.storeID = storeID
        self.generation = generation
        self.offset = offset
    }
}

public extension NSFileProviderSyncAnchor {
    init(_ anchor: FileProviderChangeAnchorEntity) throws {
        self.init(try JSONEncoder().encode(anchor))
    }

    /// `nil` for an anchor that was not made from a `FileProviderChangeAnchorEntity`.
    var changeAnchor: FileProviderChangeAnchorEntity? {
        try? JSONDecoder().decode(FileProviderChangeAnchorEntity.self, from: rawValue)
    }
}
