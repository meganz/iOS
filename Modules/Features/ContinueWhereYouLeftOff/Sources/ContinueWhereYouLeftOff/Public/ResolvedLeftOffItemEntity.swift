import Foundation
import MEGADomain

/// A resolved left-off item that contains data mapped from a resolved node
public struct ResolvedLeftOffItemEntity: Sendable, Identifiable, Equatable {
    public var id: HandleEntity { item.handle }
    public let item: LeftOffItemEntity
    /// Video duration in seconds, when the node has one.
    public let duration: TimeInterval?
    /// Whether the resolved node is sensitive and the hidden-nodes feature is active for this account.
    /// When `true` the item is blurred on the UI.
    public let isSensitive: Bool

    public init(
        item: LeftOffItemEntity,
        duration: TimeInterval? = nil,
        isSensitive: Bool = false
    ) {
        self.item = item
        self.duration = duration
        self.isSensitive = isSensitive
    }
}
