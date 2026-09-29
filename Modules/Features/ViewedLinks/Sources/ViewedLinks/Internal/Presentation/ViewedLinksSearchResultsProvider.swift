import MEGASwift
import Search

protocol ViewedLinksResultsProviding: SearchResultsProviding {
    func link(for id: ResultId) -> ViewedLinkEntity?
    func links(for ids: Set<ResultId>) -> [ViewedLinkEntity]
}

struct ViewedLinksSearchResultsProvider: ViewedLinksResultsProviding {
    private let viewedLinksUseCase: any ViewedLinksUseCaseProtocol
    private let mapper: ViewedLinkSearchResultMapper
    @Atomic private var cachedLinks: [ViewedLinkEntity] = []

    init(
        viewedLinksUseCase: some ViewedLinksUseCaseProtocol,
        mapper: ViewedLinkSearchResultMapper
    ) {
        self.viewedLinksUseCase = viewedLinksUseCase
        self.mapper = mapper
    }

    /// A read failure returns nil, which makes the Search module clear the list, so the screen shows
    /// its empty state. A cancelled read rethrows instead, leaving the rows on screen untouched.
    func refreshedSearchResults(queryRequest: SearchQuery) async throws -> SearchResultsEntity? {
        try Task.checkCancellation()
        do {
            let links = try await loadLinks(for: queryRequest)
            return resultsEntity(for: links)
        } catch ViewedLinkErrorEntity.cancelled {
            throw CancellationError()
        } catch {
            return nil
        }
    }

    func search(queryRequest: SearchQuery, lastItemIndex: Int?) async -> SearchResultsEntity? {
        guard !Task.isCancelled else { return nil }
        guard lastItemIndex == nil else { return nil }

        // A read failure shows the empty state here, because a nil first search leaves the list
        // stuck on its loading placeholder.
        let links = (try? await loadLinks(for: queryRequest)) ?? []

        // A cancelled query must not overwrite the cache a newer one already filled.
        guard !Task.isCancelled else { return nil }

        return resultsEntity(for: links)
    }

    func currentResultIds() -> [ResultId] {
        cachedLinks.map(\.handle)
    }

    func searchResultUpdateSignalSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        viewedLinksUseCase
            .changesSignalSequence()
            .map { SearchResultUpdateSignal.generic }
            .eraseToAnyAsyncSequence()
    }

    func link(for id: ResultId) -> ViewedLinkEntity? {
        cachedLinks.first { $0.handle == id }
    }

    func links(for ids: Set<ResultId>) -> [ViewedLinkEntity] {
        cachedLinks.filter { ids.contains($0.handle) }
    }

    // MARK: - Private methods

    private func loadLinks(for queryRequest: SearchQuery) async throws -> [ViewedLinkEntity] {
        let sorting = queryRequest.sorting

        return try await viewedLinksUseCase.viewedLinks(
            sortedBy: sorting.key == .name ? .name : .lastAccessed,
            ascending: sorting.direction == .ascending
        )
    }

    private func resultsEntity(for links: [ViewedLinkEntity]) -> SearchResultsEntity {
        $cachedLinks.mutate { $0 = links }

        return SearchResultsEntity(
            results: links.map { mapper.map(link: $0) },
            availableChips: [],
            appliedChips: []
        )
    }
}
