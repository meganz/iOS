import MEGADomain
import MEGASwift

public struct MockMediaTimelineRepository: MediaTimelineRepositoryProtocol {
    private let nodeUpdates: AnyAsyncSequence<[NodeEntity]>
    private let dateSectionsResult: Result<[MediaDateSectionEntity], any Error>
    private let mediaPageResult: Result<[NodeEntity], any Error>
    private let mediaPageBeforeResult: Result<[NodeEntity], any Error>
    private let mediaWindowResult: Result<[NodeEntity], any Error>

    public init(
        nodeUpdates: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence<[NodeEntity]>().eraseToAnyAsyncSequence(),
        dateSectionsResult: Result<[MediaDateSectionEntity], any Error> = .success([]),
        mediaPageResult: Result<[NodeEntity], any Error> = .success([]),
        mediaPageBeforeResult: Result<[NodeEntity], any Error> = .success([]),
        mediaWindowResult: Result<[NodeEntity], any Error> = .success([])
    ) {
        self.nodeUpdates = nodeUpdates
        self.dateSectionsResult = dateSectionsResult
        self.mediaPageResult = mediaPageResult
        self.mediaPageBeforeResult = mediaPageBeforeResult
        self.mediaWindowResult = mediaWindowResult
    }

    public func mediaNodeUpdates() -> AnyAsyncSequence<[NodeEntity]> {
        nodeUpdates
    }

    public func dateSections(
        filter: MediaTimelineFilterEntity,
        granularity: MediaDateGranularityEntity,
        excludeSensitive: Bool,
        sortOrder: MediaTimelineSortOrderEntity
    ) async throws -> [MediaDateSectionEntity] {
        try dateSectionsResult.get()
    }

    public func mediaPage(
        filter: MediaTimelineFilterEntity,
        excludeSensitive: Bool,
        sortOrder: MediaTimelineSortOrderEntity,
        after lastNode: NodeEntity?,
        limit: Int
    ) async throws -> [NodeEntity] {
        try mediaPageResult.get()
    }

    public func mediaPage(
        filter: MediaTimelineFilterEntity,
        excludeSensitive: Bool,
        sortOrder: MediaTimelineSortOrderEntity,
        before firstNode: NodeEntity,
        limit: Int
    ) async throws -> [NodeEntity] {
        try mediaPageBeforeResult.get()
    }

    public func mediaWindow(
        filter: MediaTimelineFilterEntity,
        section: MediaDateSectionEntity,
        excludeSensitive: Bool,
        sortOrder: MediaTimelineSortOrderEntity,
        offset: Int,
        limit: Int
    ) async throws -> [NodeEntity] {
        try mediaWindowResult.get()
    }
}
