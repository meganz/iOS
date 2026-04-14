import Foundation

public struct MediaImportProgressEntity: Sendable {
    /// Overall preparation progress as a fraction (0.0 to 1.0).
    /// Aggregated from individual item Progress objects.
    public let fractionCompleted: Double
    /// Number of items fully loaded and copied to sandbox.
    public let completedCount: Int
    /// Total number of items in the batch.
    public let totalCount: Int
    /// Number of items that failed to load/copy.
    public let failedCount: Int
    /// Staged file URL (relative to app container), non-nil when an item just finished successfully.
    public let latestPreparedURL: URL?
    /// The most recent item failure, non-nil when an item just failed.
    public let latestError: (any Error)?

    public init(
        fractionCompleted: Double,
        completedCount: Int,
        totalCount: Int,
        failedCount: Int,
        latestPreparedURL: URL?,
        latestError: (any Error)? = nil
    ) {
        self.fractionCompleted = fractionCompleted
        self.completedCount = completedCount
        self.totalCount = totalCount
        self.failedCount = failedCount
        self.latestPreparedURL = latestPreparedURL
        self.latestError = latestError
    }
}
