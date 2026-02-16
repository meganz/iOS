import AsyncAlgorithms
import MEGAAppPresentation
import MEGADomain
import MEGASwift
import Search

struct FavouriteSearchResultsProvider: SearchResultsProviding {
    struct Dependency {
        let fileSearchUseCase: any FilesSearchUseCaseProtocol
        let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
        let searchResultsMapper: any FavouritesSearchResultsMapping
        let downloadedNodesListener: any DownloadedNodesListening
        let nodeUseCase: any NodeUseCaseProtocol

        init(
            fileSearchUseCase: some FilesSearchUseCaseProtocol,
            sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
            searchResultsMapper: some FavouritesSearchResultsMapping,
            downloadedNodesListener: some DownloadedNodesListening,
            nodeUseCase: some NodeUseCaseProtocol
        ) {
            self.fileSearchUseCase = fileSearchUseCase
            self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
            self.searchResultsMapper = searchResultsMapper
            self.downloadedNodesListener = downloadedNodesListener
            self.nodeUseCase = nodeUseCase
        }
    }

    private let dependency: Dependency
    @Atomic private var nodes: [NodeEntity]?

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

    func currentResultIds() -> [ResultId] {
        guard let nodes else { return [] }
        return nodes.map(\.id)
    }

    func searchResultUpdateSignalSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        merge(specificNodeUpdateSequence(), genericNodeUpdateSequence())
            .eraseToAnyAsyncSequence()
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

        self.$nodes.mutate { $0 = nodes }
        let results = nodes.map { dependency.searchResultsMapper.map(node: $0) }
        return .init(results: results, availableChips: [], appliedChips: [])
    }

    private func specificNodeUpdateSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        dependency.downloadedNodesListener.downloadedNodes
            .map {
                SearchResultUpdateSignal.specific(result: dependency.searchResultsMapper.map(node: $0))
            }.eraseToAnyAsyncSequence()
    }

    private func genericNodeUpdateSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        dependency
            .nodeUseCase
            .nodeUpdates
            .compactMap { updatedNodes -> SearchResultUpdateSignal? in
                guard nodeUpdateContainsCurrentSearchResultValue(nodeUpdates: updatedNodes) else { return nil }
                return SearchResultUpdateSignal.generic
            }
            .eraseToAnyAsyncSequence()
    }

    private func nodeUpdateContainsCurrentSearchResultValue(nodeUpdates: [NodeEntity]) -> Bool {
        let currentResultIds = currentResultIds()
        return nodeUpdates.contains(where: { currentResultIds.contains($0.id) })
    }
}
