import Foundation

/// One date bucket of the media timeline, produced by grouping all media nodes by
/// their modification date. Drives the paginated timeline's placeholder skeleton
/// and the fast-scroller track length (sum of `count` across all sections).
///
/// `groupId` is stable across mutations within the same bucket and is safe to use
/// as a section key. `startDate` / `endDate` are the canonical bucket bounds and
/// are used to anchor a paginated page request to this section.
///
/// - Important: Buckets use the device's current UTC offset, so the fixed-offset SDK API may
///   differ from historical DST rules. Assign fetched nodes positionally by cumulative `count`;
///   use `groupId` for headers instead of re-grouping `startDate`.
public struct MediaDateSectionEntity: Sendable, Equatable {
    /// Local-calendar date-bucket key, e.g. "2024-07-18" (day), "2024-07" (month), "2024" (year).
    public let groupId: String
    /// Inclusive lower bound of the bucket (absolute epoch of the local-day/month/year start).
    public let startDate: Date
    /// Exclusive upper bound of the bucket (absolute epoch of the next local boundary).
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
