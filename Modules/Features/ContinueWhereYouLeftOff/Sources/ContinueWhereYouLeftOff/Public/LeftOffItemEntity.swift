import Foundation
import MEGADomain

/// A single item the user can continue where they left off, identified by its node handle.
public struct LeftOffItemEntity: Sendable, Identifiable, Equatable {
    public var id: HandleEntity { handle }
    public let handle: HandleEntity
    public let name: String
    public let lastAccessed: Date

    public init(
        handle: HandleEntity,
        name: String,
        lastAccessed: Date
    ) {
        self.handle = handle
        self.name = name
        self.lastAccessed = lastAccessed
    }
}
