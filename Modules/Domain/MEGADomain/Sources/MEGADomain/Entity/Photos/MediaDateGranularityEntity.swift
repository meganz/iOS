/// Bucket granularity for the media-timeline date-section summary. Mirrors the
/// timeline zoom levels (per-day vs per-month grouping).
public enum MediaDateGranularityEntity: Sendable, Equatable {
    case day
    case month
    case year
}
