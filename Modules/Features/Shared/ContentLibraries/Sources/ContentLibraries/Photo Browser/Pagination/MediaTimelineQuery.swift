import MEGADomain

/// The query a paginated photo library is showing — all a photo browser opened from it needs to
/// go on asking for pages of the same sequence.
///
/// Published by the screen that owns the query rather than read back out of it, so that the query
/// and the nodes handed over always come from the same commit. `nil` wherever the library is not
/// paginated, which is every content mode but the timeline.
public struct MediaTimelineQuery: Sendable, Equatable {
    public let filter: MediaTimelineFilterEntity
    public let sortOrder: MediaTimelineSortOrderEntity

    public init(filter: MediaTimelineFilterEntity, sortOrder: MediaTimelineSortOrderEntity) {
        self.filter = filter
        self.sortOrder = sortOrder
    }
}
