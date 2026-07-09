import Foundation

/// One date bucket of the media timeline, produced by grouping all media nodes by
/// their modification date. Drives the paginated timeline's placeholder skeleton
/// and the fast-scroller track length (sum of `count` across all sections).
///
/// `groupId` is stable across mutations within the same bucket and is safe to use
/// as a section key. `startDate` / `endDate` are the canonical bucket bounds and
/// are used to anchor a paginated page request to this section.
///
/// - Important: Buckets are **UTC-canonical** (midnight UTC of the day / first of the
///   month / year), NOT local-timezone. Consumers must assign fetched nodes to sections
///   **positionally by cumulative `count`** (the pages are returned in the same order as
///   the sections), NOT by re-grouping node dates with `Calendar.current` — doing the
///   latter puts near-midnight nodes in a different section than the count expects and
///   desyncs cells from the placeholder skeleton. Section headers should be labelled from
///   `groupId` (or `startDate`) — accept that near-midnight items group by UTC date.
public struct MediaDateSectionEntity: Sendable, Equatable {
    /// Display/key-only canonical date string, e.g. "2024-07". UTC-canonical.
    public let groupId: String
    /// Inclusive lower bound of the bucket (UTC epoch).
    public let startDate: Date
    /// Exclusive upper bound of the bucket (UTC epoch).
    public let endDate: Date
    /// Number of media nodes in the bucket.
    public let count: Int

    public init(groupId: String, startDate: Date, endDate: Date, count: Int) {
        self.groupId = groupId
        self.startDate = startDate
        self.endDate = endDate
        self.count = count
    }
}
