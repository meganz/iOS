import MEGADomain
import MEGASwift

public struct MockMediaTimelineUseCase: MediaTimelineUseCaseProtocol {
    private let dateSectionsResult: Result<[MediaDateSectionEntity], any Error>
    private let mediaPageResult: Result<[NodeEntity], any Error>
    private let mediaPageBeforeResult: Result<[NodeEntity], any Error>
    private let mediaWindowResult: Result<[NodeEntity], any Error>
    private let monitorDateSectionsSequence: AnyAsyncSequence<Result<[MediaDateSectionEntity], any Error>>

    public init(
        dateSectionsResult: Result<[MediaDateSectionEntity], any Error> = .success([]),
        mediaPageResult: Result<[NodeEntity], any Error> = .success([]),
        mediaPageBeforeResult: Result<[NodeEntity], any Error> = .success([]),
        mediaWindowResult: Result<[NodeEntity], any Error> = .success([]),
        monitorDateSectionsSequence: AnyAsyncSequence<Result<[MediaDateSectionEntity], any Error>> = EmptyAsyncSequence<Result<[MediaDateSectionEntity], any Error>>().eraseToAnyAsyncSequence()
    ) {
        self.dateSectionsResult = dateSectionsResult
        self.mediaPageResult = mediaPageResult
        self.mediaPageBeforeResult = mediaPageBeforeResult
        self.mediaWindowResult = mediaWindowResult
        self.monitorDateSectionsSequence = monitorDateSectionsSequence
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
        try mediaPageResult.get()
    }

    public func mediaPage(
        filter: MediaTimelineFilterEntity,
        sortOrder: MediaTimelineSortOrderEntity,
        before firstNode: NodeEntity,
        limit: Int
    ) async throws -> [NodeEntity] {
        try mediaPageBeforeResult.get()
    }

    public func mediaWindow(
        filter: MediaTimelineFilterEntity,
        section: MediaDateSectionEntity,
        sortOrder: MediaTimelineSortOrderEntity,
        offset: Int,
        limit: Int
    ) async throws -> [NodeEntity] {
        try mediaWindowResult.get()
    }

    public func monitorDateSections(
        filter: MediaTimelineFilterEntity,
        granularity: MediaDateGranularityEntity,
        sortOrder: MediaTimelineSortOrderEntity
    ) async -> AnyAsyncSequence<Result<[MediaDateSectionEntity], any Error>> {
        monitorDateSectionsSequence
    }
}
