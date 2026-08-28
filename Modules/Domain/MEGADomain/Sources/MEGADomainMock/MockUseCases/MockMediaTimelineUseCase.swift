import MEGADomain
import MEGASwift

/// Records the fetch calls a subject made against ``MockMediaTimelineUseCase`` so tests can assert
/// not just the spliced result but the actual cursor/offset parameters (anchor node, limit, section,
/// offset) and how many requests each run issued.
public actor MediaTimelineUseCaseRecorder {
    public struct PageAfterCall: Sendable, Equatable {
        public let after: NodeEntity?
        public let limit: Int
        public init(after: NodeEntity?, limit: Int) {
            self.after = after
            self.limit = limit
        }
    }
    public struct PageBeforeCall: Sendable, Equatable {
        public let before: NodeEntity
        public let limit: Int
        public init(before: NodeEntity, limit: Int) {
            self.before = before
            self.limit = limit
        }
    }
    public struct WindowCall: Sendable, Equatable {
        public let section: MediaDateSectionEntity
        public let offset: Int
        public let limit: Int
        public init(section: MediaDateSectionEntity, offset: Int, limit: Int) {
            self.section = section
            self.offset = offset
            self.limit = limit
        }
    }

    public private(set) var pageAfterCalls: [PageAfterCall] = []
    public private(set) var pageBeforeCalls: [PageBeforeCall] = []
    public private(set) var windowCalls: [WindowCall] = []
    public private(set) var sortOrders: [MediaTimelineSortOrderEntity] = []

    public init() {}

    func record(_ call: PageAfterCall) { pageAfterCalls.append(call) }
    func record(_ call: PageBeforeCall) { pageBeforeCalls.append(call) }
    func record(_ call: WindowCall) { windowCalls.append(call) }
    func record(sortOrder: MediaTimelineSortOrderEntity) { sortOrders.append(sortOrder) }

    /// Drop everything recorded so far. The initial load eagerly fetches the first window
    /// (`mediaPage(after: nil)`); call this after it to assert on a later, scroll-driven
    /// hydration in isolation.
    public func reset() {
        pageAfterCalls.removeAll()
        pageBeforeCalls.removeAll()
        windowCalls.removeAll()
        sortOrders.removeAll()
    }
}

public struct MockMediaTimelineUseCase: MediaTimelineUseCaseProtocol {
    private let dateSectionsResult: Result<[MediaDateSectionEntity], any Error>
    private let mediaPageResult: Result<[NodeEntity], any Error>
    private let mediaPageBeforeResult: Result<[NodeEntity], any Error>
    private let mediaWindowResult: Result<[NodeEntity], any Error>
    private let monitorDateSectionsSequence: AnyAsyncSequence<Result<[MediaDateSectionEntity], any Error>>
    private let excludeSensitivesResult: Bool
    private let recorder: MediaTimelineUseCaseRecorder?
    /// Runs inside every media fetch, just before the stubbed result is returned, so a test can
    /// mutate state while the subject is suspended on that fetch and assert how it reacts to losing
    /// the race (e.g. a reactive pass committing a new library mid-hydration). Re-entrant: a hook
    /// that itself triggers a fetch is called again, so one-shot it in the test when that matters.
    private let onFetch: (@MainActor () async -> Void)?

    public init(
        dateSectionsResult: Result<[MediaDateSectionEntity], any Error> = .success([]),
        mediaPageResult: Result<[NodeEntity], any Error> = .success([]),
        mediaPageBeforeResult: Result<[NodeEntity], any Error> = .success([]),
        mediaWindowResult: Result<[NodeEntity], any Error> = .success([]),
        monitorDateSectionsSequence: AnyAsyncSequence<Result<[MediaDateSectionEntity], any Error>> = EmptyAsyncSequence<Result<[MediaDateSectionEntity], any Error>>().eraseToAnyAsyncSequence(),
        excludeSensitivesResult: Bool = true,
        recorder: MediaTimelineUseCaseRecorder? = nil,
        onFetch: (@MainActor () async -> Void)? = nil
    ) {
        self.dateSectionsResult = dateSectionsResult
        self.mediaPageResult = mediaPageResult
        self.mediaPageBeforeResult = mediaPageBeforeResult
        self.mediaWindowResult = mediaWindowResult
        self.monitorDateSectionsSequence = monitorDateSectionsSequence
        self.excludeSensitivesResult = excludeSensitivesResult
        self.recorder = recorder
        self.onFetch = onFetch
    }

    public func dateSections(
        filter: MediaTimelineFilterEntity,
        granularity: MediaDateGranularityEntity,
        sortOrder: MediaTimelineSortOrderEntity
    ) async throws -> [MediaDateSectionEntity] {
        await recorder?.record(sortOrder: sortOrder)
        return try dateSectionsResult.get()
    }

    public func mediaPage(
        filter: MediaTimelineFilterEntity,
        sortOrder: MediaTimelineSortOrderEntity,
        after lastNode: NodeEntity?,
        limit: Int
    ) async throws -> [NodeEntity] {
        await recorder?.record(.init(after: lastNode, limit: limit))
        await recorder?.record(sortOrder: sortOrder)
        await onFetch?()
        return try mediaPageResult.get()
    }

    public func mediaPage(
        filter: MediaTimelineFilterEntity,
        sortOrder: MediaTimelineSortOrderEntity,
        before firstNode: NodeEntity,
        limit: Int
    ) async throws -> [NodeEntity] {
        await recorder?.record(.init(before: firstNode, limit: limit))
        await recorder?.record(sortOrder: sortOrder)
        await onFetch?()
        return try mediaPageBeforeResult.get()
    }

    public func mediaWindow(
        filter: MediaTimelineFilterEntity,
        section: MediaDateSectionEntity,
        sortOrder: MediaTimelineSortOrderEntity,
        offset: Int,
        limit: Int
    ) async throws -> [NodeEntity] {
        await recorder?.record(.init(section: section, offset: offset, limit: limit))
        await recorder?.record(sortOrder: sortOrder)
        await onFetch?()
        return try mediaWindowResult.get()
    }

    public func monitorDateSections(
        filter: MediaTimelineFilterEntity,
        granularity: MediaDateGranularityEntity,
        sortOrder: MediaTimelineSortOrderEntity
    ) async -> AnyAsyncSequence<Result<[MediaDateSectionEntity], any Error>> {
        await recorder?.record(sortOrder: sortOrder)
        return monitorDateSectionsSequence
    }

    public func excludeSensitives() async -> Bool {
        excludeSensitivesResult
    }
}
