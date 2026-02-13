import MEGADomain
import MEGASwift
import Search

struct FavouriteSearchResultsProvider: SearchResultsProviding {
    struct Dependency{
        let fileSearchUseCase: any FilesSearchUseCaseProtocol
        let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
        let searchResultsMapper: any FavouritesSearchResultsMapping

        init(
            fileSearchUseCase: some FilesSearchUseCaseProtocol,
            sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
            searchResultsMapper: some FavouritesSearchResultsMapping
        ) {
            self.fileSearchUseCase = fileSearchUseCase
            self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
            self.searchResultsMapper = searchResultsMapper
        }
    }

    private let dependency: Dependency

    init(dependency: Dependency) {
        self.dependency = dependency
    }

    func refreshedSearchResults(queryRequest: SearchQuery) async throws -> SearchResultsEntity? {
        await results(for: queryRequest)
    }

    func search(queryRequest: SearchQuery, lastItemIndex: Int?) async -> SearchResultsEntity? {
        guard lastItemIndex == nil else { return nil }
        return await results(for: queryRequest)
    }

    func currentResultIds() -> [Search.ResultId] {
        []
    }

    func searchResultUpdateSignalSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        EmptyAsyncSequence<SearchResultUpdateSignal>().eraseToAnyAsyncSequence()
    }

    // MARK: - Private methods

    private func results(for queryRequest: SearchQuery) async -> SearchResultsEntity? {
        let nodes: [NodeEntity]? = try? await dependency.fileSearchUseCase.search(
            filter: .recursive(
                searchText: queryRequest.query,
                searchDescription: queryRequest.query,
                searchTag: queryRequest.query.removingFirstLeadingHash(),
                searchTargetLocation: .folderTarget(.rootNode),
                supportCancel: true,
                sortOrderType: queryRequest.sorting.toDomainSortOrderEntity(),
                formatType: .unknown,
                sensitiveFilterOption: await dependency.sensitiveDisplayPreferenceUseCase.excludeSensitives() ? .nonSensitiveOnly : .disabled,
                favouriteFilterOption: .onlyFavourites,
                useAndForTextQuery: false
            ),
            cancelPreviousSearchIfNeeded: true
        )

        guard let nodes else {
            return .init(results: [], availableChips: [], appliedChips: [])
        }

        let results = nodes.map { dependency.searchResultsMapper.map(node: $0) }
        return .init(results: results, availableChips: [], appliedChips: [])
    }
}
