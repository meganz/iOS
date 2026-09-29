import Foundation
import MEGADomain

/// A single item the user can continue where they left off, identified by its node handle.
///
/// Note: `duration` and `isSensitive` are not persisted in the store. They are filled from the resolved live node at
/// read time.
public struct LeftOffItemEntity: Sendable, Identifiable, Equatable {
    public var id: HandleEntity { handle }
    public let handle: HandleEntity
    public let name: String
    public let lastAccessed: Date
    public let duration: TimeInterval?
    /// Whether the resolved node is sensitive and the hidden-nodes feature is active for this account.
    /// When `true` the item is blurred on the UI.
    public let isSensitive: Bool

    public init(
        handle: HandleEntity,
        name: String,
        lastAccessed: Date,
        duration: TimeInterval? = nil,
        isSensitive: Bool = false
    ) {
        self.handle = handle
        self.name = name
        self.lastAccessed = lastAccessed
        self.duration = duration
        self.isSensitive = isSensitive
    }
}

extension LeftOffItemEntity {
    /// Create a refresh copy with the up-to-date `name`, video `duration` (seconds, when positive) and `isSensitive`
    /// flag taken from the resolved live node
    func refreshed(from node: NodeEntity, isSensitive: Bool) -> LeftOffItemEntity {
        LeftOffItemEntity(
            handle: handle,
            name: node.name,
            lastAccessed: lastAccessed,
            duration: node.duration > 0 ? TimeInterval(node.duration) : nil,
            isSensitive: isSensitive
        )
    }
}
