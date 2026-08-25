extension SortOrderEntity {
    /// Maps the general node sort order onto the narrower order the paginated media
    /// timeline supports: the direction comes from this order, the timestamp column from
    /// `basis`. The timeline query orders by one of two timestamps only, so any order
    /// other than `.modificationAsc` (oldest-first) collapses to newest-first.
    ///
    /// - Parameter basis: which timestamp to order and bucket by. Kept a separate axis
    ///   because it is not part of the shared sort preference — the timeline owns it.
    public func toMediaTimelineSortOrderEntity(
        basis: MediaTimelineSortOrderEntity.TimestampBasis = .modificationTime
    ) -> MediaTimelineSortOrderEntity {
        MediaTimelineSortOrderEntity(newestFirst: self != .modificationAsc, basis: basis)
    }
}
