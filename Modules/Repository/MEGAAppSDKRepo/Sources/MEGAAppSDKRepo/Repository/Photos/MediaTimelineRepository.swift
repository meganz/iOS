import Foundation
import MEGADomain
import MEGASdk
import MEGASwift

/// Data-layer access for the paginated media timeline, backed by the SDK's flat,
/// cursor-paginated node listing (`groupAllNodesByDate` + `listAllNodesByPage`).
///
/// Stateless: it holds no photo cache. Camera Upload handles are resolved
/// on demand so they never leak into the Domain layer.
public struct MediaTimelineRepository: MediaTimelineRepositoryProtocol {
    private let sdk: MEGASdk
    private let cameraUploadNodeAccess: any NodeAccessProtocol
    private let mediaUploadNodeAccess: any NodeAccessProtocol
    private let nodeUpdatesProvider: any NodeUpdatesProviderProtocol

    public init(
        sdk: MEGASdk,
        cameraUploadNodeAccess: some NodeAccessProtocol,
        mediaUploadNodeAccess: some NodeAccessProtocol,
        nodeUpdatesProvider: some NodeUpdatesProviderProtocol
    ) {
        self.sdk = sdk
        self.cameraUploadNodeAccess = cameraUploadNodeAccess
        self.mediaUploadNodeAccess = mediaUploadNodeAccess
        self.nodeUpdatesProvider = nodeUpdatesProvider
    }

    // MARK: - MediaTimelineRepositoryProtocol

    public func mediaNodeUpdates() -> AnyAsyncSequence<[NodeEntity]> {
        nodeUpdatesProvider
            .nodeUpdates
            .compactMap { updates -> [NodeEntity]? in
                let media = updates.filter(\.fileExtensionGroup.isVisualMedia)
                return media.isEmpty ? nil : media
            }
            .eraseToAnyAsyncSequence()
    }

    public func dateSections(
        filter: MediaTimelineFilterEntity,
        granularity: MediaDateGranularityEntity,
        excludeSensitive: Bool,
        sortOrder: MediaTimelineSortOrderEntity
    ) async throws -> [MediaDateSectionEntity] {
        try await withScope(for: filter.location, empty: []) { scope in
            let megaFilter = MEGAGroupNodesByDateFilter()
            megaFilter.category = filter.mediaType.toMEGANodeFormatType
            megaFilter.granularity = granularity.toMEGAGroupNodesByDateGranularity
            scope.apply(location: { megaFilter.location = $0 },
                        include: { megaFilter.locationHandles = $0 },
                        exclude: { megaFilter.excludeLocationHandles = $0 })
            megaFilter.sensitivityFilter = excludeSensitive ? .excludeSensitive : .disabled
            // Grouping by capture time requires a media category, which `category` above always
            // is (photo / video / all visual media) — the timeline has no other scope.
            // Nil uses UTC; use the device's current offset for local date buckets.
            megaFilter.utcOffset = TimeZone.current.iso8601UTCOffset

            let cancelToken = ThreadSafeCancelToken()
            return try await withTaskCancellationHandler {
                try await withAsyncThrowingValue { completion in
                    let sections = sdk.groupAllNodesByDate(
                        with: megaFilter,
                        orderType: sortOrder.toMEGASortOrderType,
                        cancelToken: cancelToken.value) ?? []
                    completion(.success(sections.map { $0.toMediaDateSectionEntity() }))
                }
            } onCancel: {
                cancelToken.cancel()
            }
        }
    }

    public func mediaPage(
        filter: MediaTimelineFilterEntity,
        excludeSensitive: Bool,
        sortOrder: MediaTimelineSortOrderEntity,
        after lastNode: NodeEntity?,
        limit: Int
    ) async throws -> [NodeEntity] {
        try await withScope(for: filter.location, empty: []) { scope in
            let megaFilter = makeListFilter(
                mediaType: filter.mediaType, excludeSensitive: excludeSensitive,
                sortOrder: sortOrder, scope: scope)
            let cursor = lastNode.map { $0.toMEGASearchCursorOffset(for: sortOrder) }

            let cancelToken = ThreadSafeCancelToken()
            return try await withTaskCancellationHandler {
                try await withAsyncThrowingValue { completion in
                    let nodeList = sdk.listAllNodesByPage(
                        with: megaFilter,
                        orderType: sortOrder.toMEGASortOrderType,
                        maxElements: UInt(max(0, limit)),
                        cursor: cursor,
                        cancelToken: cancelToken.value)
                    completion(.success(droppingInvalidTimestamps(nodeList.toNodeEntities(), for: sortOrder)))
                }
            } onCancel: {
                cancelToken.cancel()
            }
        }
    }

    public func mediaPage(
        filter: MediaTimelineFilterEntity,
        excludeSensitive: Bool,
        sortOrder: MediaTimelineSortOrderEntity,
        before firstNode: NodeEntity,
        limit: Int
    ) async throws -> [NodeEntity] {
        try await withScope(for: filter.location, empty: []) { scope in
            let megaFilter = makeListFilter(
                mediaType: filter.mediaType, excludeSensitive: excludeSensitive,
                sortOrder: sortOrder, scope: scope)
            let cursor = firstNode.toMEGASearchCursorOffset(for: sortOrder)
            // Keyset backward paging: fetch with the FLIPPED order (rows on the other side of
            // the cursor), then reverse client-side back into display order. Drift-safe — the
            // cursor is a stable keyset position, unaffected by concurrent add/delete elsewhere.
            let flippedOrderType = sortOrder.flippingDirection.toMEGASortOrderType

            let cancelToken = ThreadSafeCancelToken()
            return try await withTaskCancellationHandler {
                try await withAsyncThrowingValue { completion in
                    let nodeList = sdk.listAllNodesByPage(
                        with: megaFilter,
                        orderType: flippedOrderType,
                        maxElements: UInt(max(0, limit)),
                        cursor: cursor,
                        cancelToken: cancelToken.value)
                    completion(.success(Array(droppingInvalidTimestamps(nodeList.toNodeEntities(), for: sortOrder).reversed())))
                }
            } onCancel: {
                cancelToken.cancel()
            }
        }
    }

    public func mediaWindow(
        filter: MediaTimelineFilterEntity,
        section: MediaDateSectionEntity,
        excludeSensitive: Bool,
        sortOrder: MediaTimelineSortOrderEntity,
        offset: Int,
        limit: Int
    ) async throws -> [NodeEntity] {
        try await withScope(for: filter.location, empty: []) { scope in
            let megaFilter = makeListFilter(
                mediaType: filter.mediaType, excludeSensitive: excludeSensitive,
                sortOrder: sortOrder, scope: scope)
            // Anchor the offset window to the date bucket so a deep jump stays O(offset-within-section)
            // instead of scanning from the top — replacing the vacuous guard anchor above with a
            // real scope. The anchor direction follows the page order.
            megaFilter.timestampAnchorStartDate = Int64(section.startDate.timeIntervalSince1970)
            megaFilter.timestampAnchorEndDate = Int64(section.endDate.timeIntervalSince1970)
            megaFilter.timestampAnchorSectionOrder = sortOrder.toAnchorOrder

            let cancelToken = ThreadSafeCancelToken()
            return try await withTaskCancellationHandler {
                try await withAsyncThrowingValue { completion in
                    let nodeList = sdk.listAllNodesByPage(
                        with: megaFilter,
                        orderType: sortOrder.toMEGASortOrderType,
                        maxElements: UInt(max(0, limit)),
                        offset: Int64(max(0, offset)),
                        cancelToken: cancelToken.value)
                    completion(.success(nodeList.toNodeEntities()))
                }
            } onCancel: {
                cancelToken.cancel()
            }
        }
    }

    // MARK: - Page post-processing

    private func droppingInvalidTimestamps(
        _ nodes: [NodeEntity],
        for sortOrder: MediaTimelineSortOrderEntity
    ) -> [NodeEntity] {
        switch sortOrder.timestampBasis {
        case .modificationTime:
            nodes.filter { $0.modificationTime.timeIntervalSince1970 > 0 }
        case .mediaCaptureTime:
            nodes.filter { ($0.mediaCaptureTime?.timeIntervalSince1970 ?? 0) > 0 }
        }
    }
    
    // MARK: - Filter building

    private func makeListFilter(
        mediaType: MediaTimelineFilterEntity.MediaType,
        excludeSensitive: Bool,
        sortOrder: MediaTimelineSortOrderEntity,
        scope: ResolvedScope
    ) -> MEGAListAllNodesFilter {
        let megaFilter = MEGAListAllNodesFilter()
        megaFilter.category = mediaType.toMEGANodeFormatType
        scope.apply(location: { megaFilter.location = $0 },
                    include: { megaFilter.locationHandles = $0 },
                    exclude: { megaFilter.excludeLocationHandles = $0 })
        megaFilter.sensitivityFilter = excludeSensitive ? .excludeSensitive : .disabled
        megaFilter.timestampAnchorSectionOrder = sortOrder.toTimestampPresenceAnchorOrder
        megaFilter.timestampAnchorStartDate = 0
        megaFilter.timestampAnchorEndDate = .max
        return megaFilter
    }

    // MARK: - Scope resolution

    /// Resolve the scope for `location`, then either short-circuit an empty scope to
    /// `empty` (skipping the SDK entirely) or run `body` with the resolved scope.
    /// Centralises the empty-scope guard so every query path inherits it — a new query
    /// method can't accidentally skip the check and regress to returning the whole library.
    private func withScope<T>(
        for location: MediaTimelineFilterEntity.Location,
        empty: [T],
        _ body: (ResolvedScope) async throws -> [T]
    ) async throws -> [T] {
        let scope = await resolveScope(for: location)
        try Task.checkCancellation()
        guard !scope.matchesNothing else { return empty }
        return try await body(scope)
    }

    private func resolveScope(for location: MediaTimelineFilterEntity.Location) async -> ResolvedScope {
        switch location {
        case .allLocations:
            return ResolvedScope(location: .cloudDriveAndVault)
        case .cloudDrive:
            return ResolvedScope(location: .cloudDriveAndVault,
                                 excludeHandles: await cameraUploadHandles())
        case .cameraUploads:
            // An include filter with no handles is treated by the SDK as "no include
            // filter" and falls back to the `location` scope — i.e. the whole library.
            // When no Camera/Media-Upload folders exist yet, that's the opposite of the
            // intent, so resolve to an explicit "match nothing" scope instead.
            let handles = await cameraUploadHandles()
            return handles.isEmpty
                ? ResolvedScope(matchesNothing: true)
                : ResolvedScope(location: .cloudDriveAndVault, includeHandles: handles)
        }
    }

    /// Camera Upload + Media Upload folder handles, omitting any that don't exist.
    private func cameraUploadHandles() async -> [HandleEntity] {
        async let camera = handle(from: cameraUploadNodeAccess)
        async let media = handle(from: mediaUploadNodeAccess)
        return await [camera, media].compactMap { $0 }
    }

    private func handle(from access: any NodeAccessProtocol) async -> HandleEntity? {
        await withCheckedContinuation { continuation in
            access.loadNode { node, _ in
                continuation.resume(returning: node?.handle)
            }
        }
    }
}

// MARK: - Scope helper

private struct ResolvedScope {
    var location: MEGAListAllNodesFilterLocation = .cloudDriveAndVault
    var includeHandles: [HandleEntity] = []
    var excludeHandles: [HandleEntity] = []
    /// The scope resolves to an empty result set (e.g. Camera-Uploads-only with no
    /// upload folders). Callers must short-circuit and return empty without hitting
    /// the SDK, whose empty-include fallback would otherwise return the whole library.
    var matchesNothing: Bool = false

    func apply(
        location setLocation: (MEGAListAllNodesFilterLocation) -> Void,
        include setInclude: ([NSNumber]?) -> Void,
        exclude setExclude: ([NSNumber]?) -> Void
    ) {
        // `location` is consulted by the SDK only when include handles are empty.
        setLocation(location)
        setInclude(includeHandles.isEmpty ? nil : includeHandles.map { NSNumber(value: $0) })
        setExclude(excludeHandles.isEmpty ? nil : excludeHandles.map { NSNumber(value: $0) })
    }
}

// MARK: - DTO → Entity / Entity → filter mapping (Data layer)

private extension TimeZone {
    /// The ISO-8601 offset required by the SDK's fixed-offset timezone API.
    var iso8601UTCOffset: String {
        let seconds = secondsFromGMT()
        let sign = seconds < 0 ? "-" : "+"
        let totalMinutes = abs(seconds) / 60
        return String(format: "%@%02d:%02d", sign, totalMinutes / 60, totalMinutes % 60)
    }
}

private extension MEGADateSection {
    func toMediaDateSectionEntity() -> MediaDateSectionEntity {
        MediaDateSectionEntity(
            groupId: groupId ?? "",
            startDate: Date(timeIntervalSince1970: TimeInterval(startDate)),
            endDate: Date(timeIntervalSince1970: TimeInterval(endDate)),
            count: Int(count))
    }
}

private extension NodeEntity {
    /// Keyset position of this node for `sortOrder`. Only the timestamp key belonging to the
    /// order is set — the SDK reads the others for a different order and ignores them here.
    func toMEGASearchCursorOffset(for sortOrder: MediaTimelineSortOrderEntity) -> MEGASearchCursorOffset {
        let cursor = MEGASearchCursorOffset()
        cursor.lastName = name
        cursor.lastHandle = handle
        switch sortOrder.timestampBasis {
        case .modificationTime:
            cursor.lastMtime = Int64(modificationTime.timeIntervalSince1970)
        case .mediaCaptureTime:
            // The one cursor field the SDK takes in milliseconds, not seconds. A negative
            // value means "unset"; anchors always come out of a page that already dropped
            // the nodes without a capture time, so the fallback is unreachable in practice.
            cursor.lastMediaTsMs = mediaCaptureTime
                .map { Int64(($0.timeIntervalSince1970 * 1000).rounded()) } ?? -1
        }
        return cursor
    }
}

private extension MediaTimelineFilterEntity.MediaType {
    var toMEGANodeFormatType: MEGANodeFormatType {
        switch self {
        case .images: .photo
        case .videos: .video
        case .allMedia: .allVisualMedia
        }
    }
}

private extension MediaTimelineSortOrderEntity {
    /// Only the modification-time and capture-time orders are valid for the paginated
    /// timeline query — the cursor carries no other sort key.
    var toMEGASortOrderType: MEGASortOrderType {
        switch self {
        case .newest: .modificationDesc
        case .oldest: .modificationAsc
        case .newestByCaptureTime: .mediaTsDesc
        case .oldestByCaptureTime: .mediaTsAsc
        }
    }

    /// Ascending anchor on this order's own timestamp column, used purely for the `<column> > 0`
    /// guard the SDK applies alongside every anchor. Paired with a lower bound of 0 so it scopes
    /// nothing else — the cursor pages must stay unscoped.
    var toTimestampPresenceAnchorOrder: MEGAListAllNodesTimestampAnchorOrder {
        switch timestampBasis {
        case .modificationTime: .modificationAsc
        case .mediaCaptureTime: .mediaTsAsc
        }
    }

    /// Anchor order matches the page order — both the timestamp column and the direction
    /// (newest → enforce the upper bound / walk back). A mismatch would scope the page to a
    /// different bucket than the one the offset counts within.
    var toAnchorOrder: MEGAListAllNodesTimestampAnchorOrder {
        switch self {
        case .newest: .modificationDesc
        case .oldest: .modificationAsc
        case .newestByCaptureTime: .mediaTsDesc
        case .oldestByCaptureTime: .mediaTsAsc
        }
    }
}

private extension MediaDateGranularityEntity {
    var toMEGAGroupNodesByDateGranularity: MEGAGroupNodesByDateGranularity {
        switch self {
        case .day: .day
        case .month: .month
        case .year: .year
        }
    }
}
