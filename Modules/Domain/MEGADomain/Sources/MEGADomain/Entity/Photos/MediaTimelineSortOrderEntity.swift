/// Sort order for the media timeline. Deliberately limited to the only orders the
/// paginated SDK query supports: modification time, newest- or oldest-first.
///
/// A narrower type than `SortOrderEntity` on purpose — `groupAllNodesByDate` rejects
/// non-modification orders, and the keyset cursor only carries the modification-time
/// key, so exposing size/label/favourite here would silently break pagination.
public enum MediaTimelineSortOrderEntity: Sendable, Equatable {
    /// Newest first (modification time descending).
    case newest
    /// Oldest first (modification time ascending).
    case oldest
}
