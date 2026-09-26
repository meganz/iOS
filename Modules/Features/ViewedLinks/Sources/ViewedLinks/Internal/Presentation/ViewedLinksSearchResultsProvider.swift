import MEGASwift
import Search

/// Serves the viewed links history to the Search module.
///
/// The store is capped, so there is no paging and no chips: every query returns the whole history.
struct ViewedLinksSearchResultsProvider: SearchResultsProviding {
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

    /// Throws rather than returning nil, because the Search module reads a nil refresh as an
    /// empty history and would wipe the list a newer query already filled.
    func refreshedSearchResults(queryRequest: SearchQuery) async throws -> SearchResultsEntity? {
        let links = try await loadLinks(for: queryRequest)
        try Task.checkCancellation()
        return resultsEntity(for: links)
    }

    func search(queryRequest: SearchQuery, lastItemIndex: Int?) async -> SearchResultsEntity? {
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

    /// The entity behind a row, so the caller can open the link or remove it.
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
