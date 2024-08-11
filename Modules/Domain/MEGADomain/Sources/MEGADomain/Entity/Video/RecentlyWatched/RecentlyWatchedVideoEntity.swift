import Foundation

public struct RecentlyWatchedVideoEntity: Sendable, Equatable {
    public let video: NodeEntity
    public let lastWatchedDate: Date?
    public let lastWatchedTimestamp: Date
    
    public init(
        video: NodeEntity,
        lastWatchedDate: Date?,
        lastWatchedTimestamp: Date
    ) {
        self.video = video
        self.lastWatchedDate = lastWatchedDate
        self.lastWatchedTimestamp = lastWatchedTimestamp
    }
}
