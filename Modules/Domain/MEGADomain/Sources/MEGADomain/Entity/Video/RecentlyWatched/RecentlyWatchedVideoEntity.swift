import Foundation

public struct RecentlyWatchedVideoEntity: Sendable, Equatable {
    public let video: NodeEntity
    public let lastWatchedDate: Date?
    public let mediaDestination: MediaDestinationEntity?
    
    public init(
        video: NodeEntity,
        lastWatchedDate: Date?,
        mediaDestination: MediaDestinationEntity?
    ) {
        self.video = video
        self.lastWatchedDate = lastWatchedDate
        self.mediaDestination = mediaDestination
    }
}
