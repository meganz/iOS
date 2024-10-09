import Foundation

public struct RecentlyOpenedNodeEntity: Sendable, Equatable {
    public let node: NodeEntity
    public let lastOpenedDate: Date?
    public let mediaDestination: MediaDestinationEntity
    
    public init(
        node: NodeEntity,
        lastOpenedDate: Date?,
        mediaDestination: MediaDestinationEntity
    ) {
        self.node = node
        self.lastOpenedDate = lastOpenedDate
        self.mediaDestination = mediaDestination
    }
}
