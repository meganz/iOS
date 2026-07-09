import AsyncAlgorithms
import MEGASwift

public protocol MediaTimelineUseCaseProtocol: Sendable {
    /// Date-bucket summary for the timeline skeleton / fast-scroller track length.
    /// Sensitivity is resolved from the account preference unless the caller has
    /// no override needs.
    func dateSections(
        filter: MediaTimelineFilterEntity,
        granularity: MediaDateGranularityEntity,
        sortOrder: MediaTimelineSortOrderEntity
    ) async throws -> [MediaDateSectionEntity]

    /// One page of media nodes, continuing after `lastNode` (nil for the first page).
    func mediaPage(
        filter: MediaTimelineFilterEntity,
        sortOrder: MediaTimelineSortOrderEntity,
        after lastNode: NodeEntity?,
        limit: Int
    ) async throws -> [NodeEntity]

    /// The page of media nodes immediately before `firstNode` (above it in display
    /// order), for drift-safe upward scrolling. Returned in display order.
    func mediaPage(
        filter: MediaTimelineFilterEntity,
        sortOrder: MediaTimelineSortOrderEntity,
        before firstNode: NodeEntity,
        limit: Int
    ) async throws -> [NodeEntity]

    /// A window of media nodes anchored at a date `section` — for fast-scroll jumps
    /// to an unloaded segment without paging from the top. `offset` is the local
    /// position within the section.
    func mediaWindow(
        filter: MediaTimelineFilterEntity,
        section: MediaDateSectionEntity,
        sortOrder: MediaTimelineSortOrderEntity,
        offset: Int,
        limit: Int
    ) async throws -> [NodeEntity]

    /// Infinite sequence that emits the date-bucket summary immediately and again
    /// whenever photo/video nodes change. Requires cancellation to terminate.
    func monitorDateSections(
        filter: MediaTimelineFilterEntity,
        granularity: MediaDateGranularityEntity,
        sortOrder: MediaTimelineSortOrderEntity
    ) async -> AnyAsyncSequence<Result<[MediaDateSectionEntity], any Error>>
}

public struct MediaTimelineUseCase<
    T: MediaTimelineRepositoryProtocol,
    V: SensitiveDisplayPreferenceUseCaseProtocol
>: MediaTimelineUseCaseProtocol {
    private let repository: T
    private let sensitiveDisplayPreferenceUseCase: V
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol

    public init(
        repository: T,
        sensitiveDisplayPreferenceUseCase: V,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol
    ) {
        self.repository = repository
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
    }

    public func dateSections(
        filter: MediaTimelineFilterEntity,
        granularity: MediaDateGranularityEntity,
        sortOrder: MediaTimelineSortOrderEntity
    ) async throws -> [MediaDateSectionEntity] {
        let excludeSensitive = await sensitiveDisplayPreferenceUseCase.excludeSensitives()
        try Task.checkCancellation()
        return try await repository.dateSections(
            filter: filter, granularity: granularity,
            excludeSensitive: excludeSensitive, sortOrder: sortOrder)
    }

    public func mediaPage(
        filter: MediaTimelineFilterEntity,
        sortOrder: MediaTimelineSortOrderEntity,
        after lastNode: NodeEntity?,
        limit: Int
    ) async throws -> [NodeEntity] {
        let excludeSensitive = await sensitiveDisplayPreferenceUseCase.excludeSensitives()
        try Task.checkCancellation()
        return try await repository.mediaPage(
            filter: filter, excludeSensitive: excludeSensitive,
            sortOrder: sortOrder, after: lastNode, limit: limit)
    }

    public func mediaPage(
        filter: MediaTimelineFilterEntity,
        sortOrder: MediaTimelineSortOrderEntity,
        before firstNode: NodeEntity,
        limit: Int
    ) async throws -> [NodeEntity] {
        let excludeSensitive = await sensitiveDisplayPreferenceUseCase.excludeSensitives()
        try Task.checkCancellation()
        return try await repository.mediaPage(
            filter: filter, excludeSensitive: excludeSensitive,
            sortOrder: sortOrder, before: firstNode, limit: limit)
    }

    public func mediaWindow(
        filter: MediaTimelineFilterEntity,
        section: MediaDateSectionEntity,
        sortOrder: MediaTimelineSortOrderEntity,
        offset: Int,
        limit: Int
    ) async throws -> [NodeEntity] {
        let excludeSensitive = await sensitiveDisplayPreferenceUseCase.excludeSensitives()
        try Task.checkCancellation()
        return try await repository.mediaWindow(
            filter: filter, section: section, excludeSensitive: excludeSensitive,
            sortOrder: sortOrder, offset: offset, limit: limit)
    }

    public func monitorDateSections(
        filter: MediaTimelineFilterEntity,
        granularity: MediaDateGranularityEntity,
        sortOrder: MediaTimelineSortOrderEntity
    ) async -> AnyAsyncSequence<Result<[MediaDateSectionEntity], any Error>> {
        // Re-fetch on media node changes and on folder-sensitivity changes: when
        // excludeSensitive is on, hiding/unhiding an ancestor folder changes the
        // section counts without emitting a node update for the media itself.
        merge(
            repository.mediaNodeUpdates().map { _ in () },
            sensitiveNodeUseCase.folderSensitivityChanged()
        )
            .map { _ in await loadSections(filter: filter, granularity: granularity, sortOrder: sortOrder) }
            .prepend { await loadSections(filter: filter, granularity: granularity, sortOrder: sortOrder) }
            .eraseToAnyAsyncSequence()
    }

    private func loadSections(
        filter: MediaTimelineFilterEntity,
        granularity: MediaDateGranularityEntity,
        sortOrder: MediaTimelineSortOrderEntity
    ) async -> Result<[MediaDateSectionEntity], any Error> {
        do {
            return .success(try await dateSections(
                filter: filter, granularity: granularity, sortOrder: sortOrder))
        } catch {
            return .failure(error)
        }
    }
}
