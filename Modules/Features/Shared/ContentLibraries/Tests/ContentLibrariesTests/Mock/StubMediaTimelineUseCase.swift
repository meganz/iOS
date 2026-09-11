import MEGADomain
import MEGASwift

/// Serves a scripted sequence of pages, one per call, and records the anchor each call asked from.
///
/// The shared `MockMediaTimelineUseCase` answers every call with the same stubbed page, which
/// cannot express what the paginator has to be tested against: successive pages, a short page
/// after a full one, or a failure between two successes.
actor MediaTimelinePageScript {
    private var forwardPages: [Result<[NodeEntity], any Error>]
    private var backwardPages: [Result<[NodeEntity], any Error>]

    /// Whole entities, not handles: a boundary node whose metadata changed keeps its handle, so
    /// only the captured sort key shows whether the cursor was a snapshot or was re-read.
    private(set) var forwardAnchors: [NodeEntity?] = []
    private(set) var backwardAnchors: [NodeEntity] = []
    private(set) var limits: [Int] = []

    /// Run while a fetch on that side is suspended, so a test can change the paginator's state
    /// mid-request. One-shot: cleared before it runs, so a second fetch on the same side proceeds
    /// straight through — which is what lets a test park one request and then issue another.
    ///
    /// A parked fetch takes its scripted page **before** parking, so pages line up with call order
    /// even while one request is held: the page a request will return is decided when it is issued,
    /// not when it is released.
    private var onForwardFetch: (@MainActor @Sendable () async -> Void)?
    private var onBackwardFetch: (@MainActor @Sendable () async -> Void)?

    init(
        forward: [Result<[NodeEntity], any Error>] = [],
        backward: [Result<[NodeEntity], any Error>] = []
    ) {
        forwardPages = forward
        backwardPages = backward
    }

    func setOnForwardFetch(_ hook: @escaping @MainActor @Sendable () async -> Void) {
        onForwardFetch = hook
    }

    func setOnBackwardFetch(_ hook: @escaping @MainActor @Sendable () async -> Void) {
        onBackwardFetch = hook
    }

    var forwardCallCount: Int { forwardAnchors.count }
    var backwardCallCount: Int { backwardAnchors.count }

    fileprivate func nextForward(anchor: NodeEntity?, limit: Int) async throws -> [NodeEntity] {
        forwardAnchors.append(anchor)
        limits.append(limit)
        let page: Result<[NodeEntity], any Error> = forwardPages.isEmpty ? .success([]) : forwardPages.removeFirst()
        let hook = onForwardFetch
        onForwardFetch = nil
        await hook?()
        return try page.get()
    }

    fileprivate func nextBackward(anchor: NodeEntity, limit: Int) async throws -> [NodeEntity] {
        backwardAnchors.append(anchor)
        limits.append(limit)
        let page: Result<[NodeEntity], any Error> = backwardPages.isEmpty ? .success([]) : backwardPages.removeFirst()
        let hook = onBackwardFetch
        onBackwardFetch = nil
        await hook?()
        return try page.get()
    }
}

struct StubMediaTimelineUseCase: MediaTimelineUseCaseProtocol {
    let script: MediaTimelinePageScript

    func mediaPage(
        filter: MediaTimelineFilterEntity,
        sortOrder: MediaTimelineSortOrderEntity,
        after lastNode: NodeEntity?,
        limit: Int
    ) async throws -> [NodeEntity] {
        try await script.nextForward(anchor: lastNode, limit: limit)
    }

    func mediaPage(
        filter: MediaTimelineFilterEntity,
        sortOrder: MediaTimelineSortOrderEntity,
        before firstNode: NodeEntity,
        limit: Int
    ) async throws -> [NodeEntity] {
        try await script.nextBackward(anchor: firstNode, limit: limit)
    }

    func dateSections(
        filter: MediaTimelineFilterEntity,
        granularity: MediaDateGranularityEntity,
        sortOrder: MediaTimelineSortOrderEntity
    ) async throws -> [MediaDateSectionEntity] { [] }

    func mediaWindow(
        filter: MediaTimelineFilterEntity,
        section: MediaDateSectionEntity,
        sortOrder: MediaTimelineSortOrderEntity,
        offset: Int,
        limit: Int
    ) async throws -> [NodeEntity] { [] }

    func monitorDateSections(
        filter: MediaTimelineFilterEntity,
        granularity: MediaDateGranularityEntity,
        sortOrder: MediaTimelineSortOrderEntity
    ) async -> AnyAsyncSequence<Result<[MediaDateSectionEntity], any Error>> {
        EmptyAsyncSequence<Result<[MediaDateSectionEntity], any Error>>().eraseToAnyAsyncSequence()
    }

    func excludeSensitives() async -> Bool { false }
}

/// Parks a request until a test releases it. One-shot: once opened it never blocks again.
actor TestGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var isOpen = false

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { continuation = $0 }
    }

    func open() {
        isOpen = true
        continuation?.resume()
        continuation = nil
    }
}

/// Yields until `condition` holds, so a test can act while a request is parked without sleeping.
/// Bounded, so a condition that never holds fails an assertion instead of hanging the suite.
func yieldUntil(_ condition: @Sendable () async -> Bool) async {
    for _ in 0..<10_000 {
        if await condition() { return }
        await Task.yield()
    }
}
