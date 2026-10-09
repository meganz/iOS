import MEGASwift
import Search

protocol LeftOffItemsResultsProviding: SearchResultsProviding {
    func items(for ids: Set<ResultId>) -> [LeftOffItemEntity]
}

struct LeftOffItemsSearchResultsProvider: LeftOffItemsResultsProviding {
    private let leftOffItemsUseCase: any LeftOffItemsUseCaseProtocol
    private let mapper: LeftOffItemSearchResultMapper
    @Atomic private var cachedItems: [ResolvedLeftOffItemEntity] = []

    init(
        leftOffItemsUseCase: some LeftOffItemsUseCaseProtocol,
        mapper: LeftOffItemSearchResultMapper
    ) {
        self.leftOffItemsUseCase = leftOffItemsUseCase
        self.mapper = mapper
    }

    func refreshedSearchResults(queryRequest: SearchQuery) async throws -> SearchResultsEntity? {
        try Task.checkCancellation()
        do {
            let items = try await loadItems(for: queryRequest)
            return resultsEntity(for: items)
        } catch LeftOffItemErrorEntity.cancelled {
            throw CancellationError()
        } catch {
            return nil
        }
    }

    func search(queryRequest: SearchQuery, lastItemIndex: Int?) async -> SearchResultsEntity? {
        guard !Task.isCancelled else { return nil }
        guard lastItemIndex == nil else { return nil }

        let items = (try? await loadItems(for: queryRequest)) ?? []

        guard !Task.isCancelled else { return nil }

        return resultsEntity(for: items)
    }

    func currentResultIds() -> [ResultId] {
        cachedItems.map(\.id)
    }

    func searchResultUpdateSignalSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        // Note about the .prepend(()):
        // When we open a left off item inside ContinueWhereYouLeftOffView and close it, we'll upsert that item
        // to the store and we would expect the SearchResultsView to refresh and reflect the upsert
        // which will put the item to the top of the list
        // However the upsert happens in parallel with the refresh, so the refresh won't catch that upsert and
        // won't correctly update the UI
        // A workaround is to prepend trigger an extra update signal after the refresh, then
        // searchResultUpdateSignalSequence will update and reflect the upsert correctly
        leftOffItemsUseCase
            .changesSignalSequence()
            .prepend(())
            .map { SearchResultUpdateSignal.generic }
            .eraseToAnyAsyncSequence()
    }

    func items(for ids: Set<ResultId>) -> [LeftOffItemEntity] {
        cachedItems
            .filter { ids.contains($0.id) }
            .map(\.item)
    }

    // MARK: - Private methods

    private func loadItems(for queryRequest: SearchQuery) async throws -> [ResolvedLeftOffItemEntity] {
        let sorting = queryRequest.sorting

        return try await leftOffItemsUseCase.items(
            sortedBy: sorting.key == .name ? .name : .lastAccessed,
            ascending: sorting.direction == .ascending
        )
    }

    private func resultsEntity(for items: [ResolvedLeftOffItemEntity]) -> SearchResultsEntity {
        $cachedItems.mutate { $0 = items }

        return SearchResultsEntity(
            results: items.map { mapper.map(item: $0) },
            availableChips: [],
            appliedChips: []
        )
    }
}
