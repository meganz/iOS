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

    public init() {}

    func record(_ call: PageAfterCall) { pageAfterCalls.append(call) }
    func record(_ call: PageBeforeCall) { pageBeforeCalls.append(call) }
    func record(_ call: WindowCall) { windowCalls.append(call) }
}

public struct MockMediaTimelineUseCase: MediaTimelineUseCaseProtocol {
    private let dateSectionsResult: Result<[MediaDateSectionEntity], any Error>
    private let mediaPageResult: Result<[NodeEntity], any Error>
    private let mediaPageBeforeResult: Result<[NodeEntity], any Error>
    private let mediaWindowResult: Result<[NodeEntity], any Error>
    private let monitorDateSectionsSequence: AnyAsyncSequence<Result<[MediaDateSectionEntity], any Error>>
    private let recorder: MediaTimelineUseCaseRecorder?

    public init(
        dateSectionsResult: Result<[MediaDateSectionEntity], any Error> = .success([]),
        mediaPageResult: Result<[NodeEntity], any Error> = .success([]),
        mediaPageBeforeResult: Result<[NodeEntity], any Error> = .success([]),
        mediaWindowResult: Result<[NodeEntity], any Error> = .success([]),
        monitorDateSectionsSequence: AnyAsyncSequence<Result<[MediaDateSectionEntity], any Error>> = EmptyAsyncSequence<Result<[MediaDateSectionEntity], any Error>>().eraseToAnyAsyncSequence(),
        recorder: MediaTimelineUseCaseRecorder? = nil
    ) {
        self.dateSectionsResult = dateSectionsResult
        self.mediaPageResult = mediaPageResult
        self.mediaPageBeforeResult = mediaPageBeforeResult
        self.mediaWindowResult = mediaWindowResult
        self.monitorDateSectionsSequence = monitorDateSectionsSequence
        self.recorder = recorder
    }

    public func dateSections(
        filter: MediaTimelineFilterEntity,
        granularity: MediaDateGranularityEntity,
        sortOrder: MediaTimelineSortOrderEntity
    ) async throws -> [MediaDateSectionEntity] {
        try dateSectionsResult.get()
    }

    public func mediaPage(
        filter: MediaTimelineFilterEntity,
        sortOrder: MediaTimelineSortOrderEntity,
        after lastNode: NodeEntity?,
        limit: Int
    ) async throws -> [NodeEntity] {
        await recorder?.record(.init(after: lastNode, limit: limit))
        return try mediaPageResult.get()
    }

    public func mediaPage(
        filter: MediaTimelineFilterEntity,
        sortOrder: MediaTimelineSortOrderEntity,
        before firstNode: NodeEntity,
        limit: Int
    ) async throws -> [NodeEntity] {
        await recorder?.record(.init(before: firstNode, limit: limit))
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
        return try mediaWindowResult.get()
    }

    public func monitorDateSections(
        filter: MediaTimelineFilterEntity,
        granularity: MediaDateGranularityEntity,
        sortOrder: MediaTimelineSortOrderEntity
    ) async -> AnyAsyncSequence<Result<[MediaDateSectionEntity], any Error>> {
        monitorDateSectionsSequence
    }
}
