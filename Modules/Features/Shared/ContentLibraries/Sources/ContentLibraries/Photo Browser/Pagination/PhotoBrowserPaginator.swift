import MEGADomain

/// The browsing sequence the photo browser pages through when it is opened on a paginated media
/// timeline.
///
/// It owns the loaded run of nodes, both keyset cursors and the `i of n` bookkeeping for one
/// browsing session: the entry point hands over a contiguous window
/// (``PhotoBrowserPaginationContext``) and the browser extends it in either direction from here
/// on, without reading or writing the timeline it was opened from.
///
/// Two things it deliberately does not do:
///
/// - It does not reconcile items that appear *inside* the loaded run. The sequence converges at
///   its two frontiers only, which is why `i` is a position in this sequence rather than a rank
///   in the source — see ``displayPosition(forIndex:)``.
/// - It does not track membership changes *outside* the loaded run — an upload landing above it,
///   or a deletion in the region not yet loaded. Deciding whether such a node even belongs to the
///   browsing query needs location and inherited-sensitivity facts a `NodeEntity` does not carry,
///   so the estimate is left alone rather than moved on a guess; a frozen number beats a wrong one
///   that never self-corrects. ``calibrateAtBoundaries()`` is the exception — at the two ends the
///   sequence can see the source directly.
/// - It does not re-apply any per-node filter to a fetched page. The section counts and the
///   fetched nodes share one query filter, and filtering here would desynchronise them.
@MainActor
public final class PhotoBrowserPaginator {

    // MARK: - Nested types

    public enum Direction: Sendable, CaseIterable {
        /// Towards the start of the sequence, above the loaded run in display order.
        case backward
        /// Towards the end of the sequence.
        case forward
    }

    /// Whether more items can still be fetched on one side of the loaded run.
    public enum BoundaryAvailability: Sendable, Equatable {
        /// More items may exist; a fetch is worth issuing.
        case available
        /// The SDK returned a short page on this side. True of the current revision only — an
        /// explicit refresh re-evaluates it.
        case exhausted
        /// The last attempt failed or was cancelled. Retryable.
        case unresolved
    }

    public enum Outcome: Sendable, Equatable {
        /// A page arrived and `insertedCount` of its nodes entered the sequence. Zero means every
        /// node in it was already loaded or was vetoed; the cursor advanced regardless, so asking
        /// again makes progress rather than re-fetching the same page.
        case loaded(insertedCount: Int)
        /// No query was issued: this side is already exhausted, or a request is already in flight.
        case notNeeded
        /// The page was short and brought nothing new. This side is now `.exhausted`.
        case reachedBoundary
        /// Retryable failure; the error itself is logged rather than carried, since the caller's
        /// only decision is whether to ask again. Availability on this side is left `.unresolved`.
        case failed
        case cancelled
    }

    /// Provisional until measured on device against thumbnail prefetch cost.
    public static let defaultPageSize = 100

    // MARK: - Dependencies

    private let useCase: any MediaTimelineUseCaseProtocol
    private let pageSize: Int

    // MARK: - Query

    private var filter: MediaTimelineFilterEntity
    private var sortOrder: MediaTimelineSortOrderEntity

    // MARK: - Sequence

    public private(set) var nodes: [NodeEntity] = []
    /// Position of `nodes.first` in the source. An estimate once browsing starts; see
    /// ``displayPosition(forIndex:)``.
    public private(set) var globalStartIndex = 0
    /// Locally maintained item count for the title. An estimate: it starts from the handover, is
    /// raised to cover what the sequence can reach, comes down by the items actually seen leaving
    /// it, and is normalised to the loaded count once both ends are exhausted. It is never an
    /// assertion about the source's live total.
    public private(set) var totalCount = 0

    private var loadedHandles: Set<HandleEntity> = []
    private var boundaryAvailability: [Direction: BoundaryAvailability] = [:]

    /// Keyset anchors, captured from the page that established them and never refreshed from the
    /// displayed entities. A metadata update that moves a boundary node's sort time must not move
    /// the point paging continues from: everything between the old position and the new one would
    /// be skipped for good.
    private var backwardCursor: NodeEntity?
    private var forwardCursor: NodeEntity?

    // MARK: - In-flight protection

    /// One fetch in flight, and the removals it has to answer for.
    private struct ActiveRequest {
        let direction: Direction
        /// The sequence this request belongs to. Once ``generation`` moves past it the request is
        /// stale: it neither commits nor holds its side of the new sequence.
        let generation: Int
        /// Handles reported as removed *after* this request started — see ``vetoPagesInFlight(for:)``.
        var vetoedHandles: Set<HandleEntity> = []
    }

    private var activeRequests: [Int: ActiveRequest] = [:]
    private var nextRequestID = 0

    /// Bumped by ``reset(to:)``. A page that returns afterwards belongs to a sequence that no
    /// longer exists.
    private var generation = 0

    // MARK: - Lifecycle

    public init(
        context: PhotoBrowserPaginationContext,
        useCase: some MediaTimelineUseCaseProtocol,
        pageSize: Int = PhotoBrowserPaginator.defaultPageSize
    ) {
        self.useCase = useCase
        self.pageSize = max(1, pageSize)
        filter = context.filter
        sortOrder = context.sortOrder
        install(context)
    }

    /// Rebuilds the sequence from a fresh handover, for an explicit refresh. Pages still in flight
    /// are discarded when they return, and every `.exhausted` conclusion is re-opened.
    public func reset(to context: PhotoBrowserPaginationContext) {
        generation += 1
        filter = context.filter
        sortOrder = context.sortOrder
        // Requests already in flight are left registered so each still clears its own entry when
        // it returns. They no longer block the new sequence: every check below is generation-scoped.
        install(context)
    }

    private func install(_ context: PhotoBrowserPaginationContext) {
        nodes = Self.deduplicated(context.nodes)
        loadedHandles = Set(nodes.map(\.handle))
        globalStartIndex = max(0, context.globalStartIndex)
        totalCount = max(context.totalCount, globalStartIndex + nodes.count)
        backwardCursor = nodes.first
        forwardCursor = nodes.last
        // With nothing handed over there is no node to express a backward cursor with, and the
        // API takes a node rather than an absolute offset. Forward from nil starts at the top.
        boundaryAvailability = [
            .backward: nodes.isEmpty ? .exhausted : .available,
            .forward: .available
        ]
    }

    // MARK: - Reading

    public func availability(for direction: Direction) -> BoundaryAvailability {
        boundaryAvailability[direction] ?? .available
    }

    /// The `i of n` to show for the item at `index` of the loaded run, or `nil` when there is
    /// nothing to title.
    ///
    /// `i` is the item's position in *this browsing sequence*, not its rank in the source. The two
    /// diverge when something is inserted inside the loaded run: that item never enters the
    /// sequence, so no single offset could make both the items before it and the items after it
    /// read correctly. `n` is maintained locally and is likewise an estimate.
    ///
    /// What is guaranteed is the rendering invariant: `1 <= i <= n`, and `n` is never below the
    /// number of items the sequence can actually reach.
    public func displayPosition(forIndex index: Int) -> (index: Int, total: Int)? {
        guard nodes.indices.contains(index) else { return nil }
        let total = max(totalCount, globalStartIndex + nodes.count)
        return (min(max(globalStartIndex + index + 1, 1), total), total)
    }

    // MARK: - Paging

    /// Fetches one page on `direction` and merges it into the sequence.
    ///
    /// Latest-only is not applied here: a second call while one is in flight on the same side
    /// returns ``Outcome/notNeeded`` rather than replacing it, because both would ask the same
    /// cursor the same question.
    @discardableResult
    public func loadMore(_ direction: Direction) async -> Outcome {
        let anchor = cursor(for: direction)
        guard availability(for: direction) != .exhausted,
              !isRequestInFlight(direction),
              direction == .forward || anchor != nil else { return .notNeeded }
        guard !Task.isCancelled else { return .cancelled }

        let requestGeneration = generation
        let requestID = nextRequestID
        nextRequestID += 1
        activeRequests[requestID] = ActiveRequest(direction: direction, generation: requestGeneration)
        defer { activeRequests[requestID] = nil }

        do {
            let page = try await fetchPage(direction, anchor: anchor)
            guard let request = activeRequests[requestID], request.generation == generation else {
                return .cancelled
            }
            // The layer below does not have to throw on cancellation — it may well return a page,
            // or an empty one. Committing either would mutate the sequence, and an empty one would
            // also call the side exhausted, so the check happens before any state is touched.
            guard !Task.isCancelled else {
                markUnresolved(direction, generation: requestGeneration)
                return .cancelled
            }
            if page.isEmpty {
                MEGALogWarning("[PhotoBrowser] empty \(direction) page, first page: \(anchor == nil)")
            }
            return commit(page, from: direction, vetoing: request.vetoedHandles)
        } catch is CancellationError {
            markUnresolved(direction, generation: requestGeneration)
            return .cancelled
        } catch {
            MEGALogError("[PhotoBrowser] \(direction) page failed: \(error)")
            markUnresolved(direction, generation: requestGeneration)
            return .failed
        }
    }

    private func isRequestInFlight(_ direction: Direction) -> Bool {
        activeRequests.values.contains { $0.direction == direction && $0.generation == generation }
    }

    private func fetchPage(_ direction: Direction, anchor: NodeEntity?) async throws -> [NodeEntity] {
        switch direction {
        case .forward:
            return try await useCase.mediaPage(
                filter: filter, sortOrder: sortOrder, after: anchor, limit: pageSize)
        case .backward:
            guard let anchor else { return [] }
            return try await useCase.mediaPage(
                filter: filter, sortOrder: sortOrder, before: anchor, limit: pageSize)
        }
    }

    private func commit(
        _ page: [NodeEntity],
        from direction: Direction,
        vetoing vetoedHandles: Set<HandleEntity>
    ) -> Outcome {
        // Exhaustion reads the page as the SDK returned it, before local de-duplication. A full
        // page that happens to be entirely already-loaded is not the end of the source; counting
        // what was inserted instead would call the end early. An empty page is ambiguous per the
        // SDK (no more results, or inputs rejected) and is taken as the end: rejected inputs are a
        // programming error, they reproduce, and a refresh re-opens the conclusion.
        let reachedEnd = page.count < pageSize
        boundaryAvailability[direction] = reachedEnd ? .exhausted : .available
        advanceCursor(with: page, direction: direction)

        let admitted = page.filter {
            !loadedHandles.contains($0.handle) && !vetoedHandles.contains($0.handle)
        }
        insert(admitted, from: direction)
        calibrateAtBoundaries()
        totalCount = max(totalCount, globalStartIndex + nodes.count)

        guard !admitted.isEmpty else { return reachedEnd ? .reachedBoundary : .loaded(insertedCount: 0) }
        return .loaded(insertedCount: admitted.count)
    }

    /// The cursor follows the page the SDK returned, never what was inserted. A page whose nodes
    /// were all de-duplicated away still moves it — otherwise a node that changed sort position
    /// and is met again would have the same page requested forever.
    private func advanceCursor(with page: [NodeEntity], direction: Direction) {
        switch direction {
        case .forward:
            if let last = page.last { forwardCursor = last }
            // Only an empty handover leaves this nil, and a forward fetch then starts from the top
            // of the source, so the page's first node is the source's first item. Without this the
            // backward anchor would stay nil and the run could never be recognised as starting at
            // the source's start.
            if backwardCursor == nil { backwardCursor = page.first }
        case .backward:
            if let first = page.first { backwardCursor = first }
        }
    }

    private func insert(_ admitted: [NodeEntity], from direction: Direction) {
        guard !admitted.isEmpty else { return }
        loadedHandles.formUnion(admitted.map(\.handle))
        switch direction {
        case .forward:
            nodes.append(contentsOf: admitted)
        case .backward:
            nodes.insert(contentsOf: admitted, at: 0)
            // Relative, and exact as such: these items sit immediately before the previous start.
            // The floor only stops the estimate going negative, it does not mean the start was reached.
            globalStartIndex = max(0, globalStartIndex - admitted.count)
        }
    }

    /// Calibrates the start where the sequence can see the source, and normalises the title once
    /// both ends are in hand.
    private func calibrateAtBoundaries() {
        guard reachedStartOfSource else { return }
        globalStartIndex = 0
        guard availability(for: .forward) == .exhausted else { return }
        // Normalisation, not truth. Both ends exhausted proves the *sequence* is self-consistent,
        // never that it equals the source: an item inserted between two loaded photos never enters
        // the sequence, and paging both ends will not find it, so the real total can be higher.
        // What this buys is that the last photo reads `n of n` instead of leaving the user stuck at
        // `299 of 300`. Forward exhaustion alone could not justify it — it says nothing about where
        // the run starts, so it cannot validate a total.
        totalCount = nodes.count
    }

    /// True when nothing in the source sorts before the run's first item: the backward side is
    /// exhausted and its cursor still names the item the run now starts with. A backward page does
    /// find items inserted above the run, so this one is exact — at this moment rather than for
    /// good, since an item added above the run drifts the start again.
    private var reachedStartOfSource: Bool {
        availability(for: .backward) == .exhausted && nodes.first?.handle == backwardCursor?.handle
    }

    private func cursor(for direction: Direction) -> NodeEntity? {
        switch direction {
        case .forward: forwardCursor
        case .backward: backwardCursor
        }
    }

    private func markUnresolved(_ direction: Direction, generation requestGeneration: Int) {
        guard requestGeneration == generation else { return }
        boundaryAvailability[direction] = .unresolved
    }

    // MARK: - Node updates

    /// Drops nodes that left the browsing sequence and returns how many actually did.
    ///
    /// Counting the handles that were really in the run — rather than the events received — is
    /// what keeps `n` honest: the browser subscribes to a general node stream whose events may
    /// fall outside the query, may repeat, and include moves, which `removedChangeTypeNodes()`
    /// reports as removals without the source count necessarily changing.
    @discardableResult
    public func applyRemovals(of removed: [NodeEntity]) -> Int {
        vetoPagesInFlight(for: removed)

        let handles = Set(removed.map(\.handle)).intersection(loadedHandles)
        guard !handles.isEmpty else { return 0 }

        nodes.removeAll { handles.contains($0.handle) }
        loadedHandles.subtract(handles)
        // The start does not move, and that is exact: every removed item sat at or after it, so
        // what follows slides up into the same positions.
        totalCount = max(totalCount - handles.count, globalStartIndex + nodes.count)
        // Cursors are left alone. They are keyset values built from a node's own sort key, so they
        // stay well defined whether or not that row still exists on the server.
        return handles.count
    }

    /// Keeps a page that is *already* in flight from committing a node that has just been removed.
    ///
    /// Every reported handle is vetoed, not only the ones that were in the run: the page may carry
    /// a node never loaded here, which handle de-duplication would happily let through, and the
    /// entity it carries is a value copy whose `isRemoved` is still `false`.
    ///
    /// The veto reaches only the requests open at this moment, which is the whole point.
    /// `removedChangeTypeNodes()` counts a move as a removal, so a query issued *after* the event
    /// may legitimately return the node again — vetoing that page too would drop it while the
    /// cursor moved past, losing it for the rest of the session.
    private func vetoPagesInFlight(for removed: [NodeEntity]) {
        guard !activeRequests.isEmpty else { return }
        let handles = Set(removed.map(\.handle))
        for id in activeRequests.keys {
            activeRequests[id]?.vetoedHandles.formUnion(handles)
        }
    }

    /// Replaces displayed entities by handle after a metadata change.
    ///
    /// Cursors are deliberately untouched: an updated sort time on a boundary node would otherwise
    /// move where paging resumes and skip everything between the old position and the new one. The
    /// node keeps its place in the sequence even though its sort position has changed elsewhere,
    /// which is the accepted cost of not reconciling the inside of the run.
    public func applyMetadataUpdates(of updated: [NodeEntity]) {
        guard !updated.isEmpty else { return }
        let byHandle = Dictionary(updated.map { ($0.handle, $0) }, uniquingKeysWith: { _, latest in latest })
        nodes = nodes.map { byHandle[$0.handle] ?? $0 }
    }

    private static func deduplicated(_ nodes: [NodeEntity]) -> [NodeEntity] {
        var seen: Set<HandleEntity> = []
        return nodes.filter { seen.insert($0.handle).inserted }
    }
}
