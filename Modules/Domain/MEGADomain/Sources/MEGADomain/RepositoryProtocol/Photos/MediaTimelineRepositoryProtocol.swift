import MEGASwift

/// Data access for the paginated media timeline.
///
/// Backed by the SDK's flat, cursor-paginated node listing:
/// - `dateSections` groups all matching media into date buckets (the summary used
///   for the placeholder skeleton and fast-scroller track length).
/// - `mediaPage` fetches one page of node details, continuing after the last node
///   of the previous page (keyset / cursor pagination — no items skipped when nodes
///   are added or removed between pages).
///
/// Camera Upload handle resolution and DTO → entity mapping live in the
/// implementation; callers pass only scope + sensitivity + sort.
///
/// - Important: All results are the SDK's visual-media set filtered only by scope /
///   sensitivity — there is **no `hasThumbnail` filter** (the SDK query cannot express
///   it, and `dateSections` returns counts, not nodes, so it cannot be post-filtered).
///   The counts (`dateSections`) and the fetched nodes (`mediaPage` / `mediaWindow`)
///   therefore share one filter and stay mutually consistent. Consumers MUST NOT
///   re-apply a per-node filter such as `hasThumbnail` to the fetched pages — doing so
///   makes rendered cells fewer than the counts, breaking the placeholder skeleton,
///   scroll-track length, section item counts and empty state. (This differs from the
///   legacy full-load timeline, which filtered `hasThumbnail` client-side.)
public protocol MediaTimelineRepositoryProtocol: Sendable {
    /// Infinite sequence of photo/video node updates (already filtered to visual
    /// media; empty batches are dropped). Used to re-fetch the date-bucket summary
    /// when the library changes. Requires cancellation to terminate.
    func mediaNodeUpdates() -> AnyAsyncSequence<[NodeEntity]>

    /// Group all matching media nodes into date buckets across the whole scope.
    /// - Returns: sections ordered per `sortOrder` (newest- or oldest-first).
    /// - Throws: `CancellationError`.
    func dateSections(
        filter: MediaTimelineFilterEntity,
        granularity: MediaDateGranularityEntity,
        excludeSensitive: Bool,
        sortOrder: MediaTimelineSortOrderEntity
    ) async throws -> [MediaDateSectionEntity]

    /// Fetch one page of media nodes, starting after `lastNode` (nil for the first page).
    /// - Parameters:
    ///   - lastNode: the last node of the previous page; the cursor is built from it internally.
    ///   - limit: maximum number of nodes to return (0 = no limit).
    /// - Throws: `CancellationError`.
    func mediaPage(
        filter: MediaTimelineFilterEntity,
        excludeSensitive: Bool,
        sortOrder: MediaTimelineSortOrderEntity,
        after lastNode: NodeEntity?,
        limit: Int
    ) async throws -> [NodeEntity]

    /// Fetch the page of media nodes immediately BEFORE `firstNode` (i.e. above it in
    /// display order) — for drift-safe upward scrolling. Keyset-based, so page seams
    /// stay consistent under concurrent add/delete. The result is returned already in
    /// display order (ready to prepend); the flipped-order fetch + reversal is internal.
    /// - Parameters:
    ///   - firstNode: the first (top) node of the currently loaded range.
    ///   - limit: maximum number of nodes to return (0 = no limit).
    /// - Throws: `CancellationError`.
    func mediaPage(
        filter: MediaTimelineFilterEntity,
        excludeSensitive: Bool,
        sortOrder: MediaTimelineSortOrderEntity,
        before firstNode: NodeEntity,
        limit: Int
    ) async throws -> [NodeEntity]

    /// Fetch a window of media nodes anchored at a date section — used for random
    /// access (fast-scroll jump) without paging from the top.
    /// - Parameters:
    ///   - section: the date bucket to anchor at (its start/end bounds).
    ///   - offset: local position within the section (0 = first node of the section).
    ///   - limit: window size (0 = no limit).
    /// - Note: offset positions are not stable under concurrent add/delete; re-fetch on change.
    /// - Throws: `CancellationError`.
    func mediaWindow(
        filter: MediaTimelineFilterEntity,
        section: MediaDateSectionEntity,
        excludeSensitive: Bool,
        sortOrder: MediaTimelineSortOrderEntity,
        offset: Int,
        limit: Int
    ) async throws -> [NodeEntity]
}
