import MEGADomain

/// The one-shot handover an entry point makes when it opens the photo browser on a paginated
/// media timeline.
///
/// Every field is a value read at open time. The browser keeps its own sequence from then on and
/// never reads the presenting screen's state again, so nothing here is a live reference and
/// nothing flows back.
public struct PhotoBrowserPaginationContext: Sendable, Equatable {
    /// The contiguous run of real nodes around the tapped one, in display order. Contiguous is a
    /// requirement, not a preference: the sequence grows only at its two ends, so a gap handed in
    /// here can never be filled.
    ///
    /// Unique by handle — repeats are dropped by `init`. Build the browser's data provider from
    /// this array rather than from whatever was passed in: the paginator counts positions in it,
    /// and a provider holding one node more would put the two index spaces out of step with
    /// nothing in either to notice.
    public let nodes: [NodeEntity]

    /// Position of `nodes.first` in the source at open time. The browser maintains it locally
    /// afterwards; see ``PhotoBrowserPaginator/displayPosition(forIndex:)`` for what it means once
    /// browsing has started.
    public let globalStartIndex: Int

    /// Item count of the whole source at open time — the sum of the date-section counts the
    /// timeline already holds, not the size of loaded `nodes`.
    public let totalCount: Int

    /// Scope of the query the sequence continues. Must be the same one the handed-over nodes came
    /// from, or the pages that follow will not line up with them.
    public let filter: MediaTimelineFilterEntity

    /// Order of the query the sequence continues, including which timestamp it sorts by.
    public let sortOrder: MediaTimelineSortOrderEntity

    /// How far either side of the tapped item the handed-over run is cut. Provisional until
    /// measured on device: wide enough that the first swipes stay inside it, narrow enough that a
    /// long hydrated stretch is not handed over whole — doing that would leave the paging paths
    /// unreached in ordinary use.
    public static let defaultInitialRadius = 100

    public init(
        nodes: [NodeEntity],
        globalStartIndex: Int,
        totalCount: Int,
        filter: MediaTimelineFilterEntity,
        sortOrder: MediaTimelineSortOrderEntity
    ) {
        var seen: Set<HandleEntity> = []
        self.nodes = nodes.filter { seen.insert($0.handle).inserted }
        self.globalStartIndex = globalStartIndex
        self.totalCount = totalCount
        self.filter = filter
        self.sortOrder = sortOrder
    }
}
