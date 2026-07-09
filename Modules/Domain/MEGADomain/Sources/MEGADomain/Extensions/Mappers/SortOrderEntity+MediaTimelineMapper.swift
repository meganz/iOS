extension SortOrderEntity {
    /// Maps the general node sort order onto the narrower order the paginated media
    /// timeline supports. The timeline query only orders by modification time, so any
    /// order other than `.modificationAsc` (oldest-first) collapses to newest-first.
    public func toMediaTimelineSortOrderEntity() -> MediaTimelineSortOrderEntity {
        switch self {
        case .modificationAsc: .oldest
        default: .newest
        }
    }
}
