import MEGADomain
import MEGASwift
import Search

struct FolderLinkSearchResultsProvider: SearchResultsProviding {
    private let nodeHandle: HandleEntity
    private let folderLinkSearchUseCase: any FolderLinkSearchUseCaseProtocol
    private let folderSearchResultMapper: any FolderLinkSearchResultMapperProtocol
    @Atomic private var allResultIds: [ResultId] = []
    
    init(
        nodeHandle: HandleEntity,
        folderLinkSearchUseCase: some FolderLinkSearchUseCaseProtocol = FolderLinkSearchUseCase(),
        folderSearchResultMapper: some FolderLinkSearchResultMapperProtocol
    ) {
        self.nodeHandle = nodeHandle
        self.folderLinkSearchUseCase = folderLinkSearchUseCase
        self.folderSearchResultMapper = folderSearchResultMapper
    }
    
    func refreshedSearchResults(queryRequest: Search.SearchQuery) async throws -> Search.SearchResultsEntity? {
        await search(queryRequest: queryRequest, lastItemIndex: nil)
    }
    
    func search(queryRequest: Search.SearchQuery, lastItemIndex: Int?) async -> Search.SearchResultsEntity? {
        if lastItemIndex != nil {
            return SearchResultsEntity.empty
        }
        
        let children = await folderLinkSearchUseCase.children(of: nodeHandle)
        
        let searchResultEntity = apply(searchQuery: queryRequest, for: children)
        $allResultIds.mutate { $0 = searchResultEntity.results.map(\.id) }
        return searchResultEntity
    }
    
    func currentResultIds() -> [Search.ResultId] {
        allResultIds
    }
    
    func searchResultUpdateSignalSequence() -> MEGASwift.AnyAsyncSequence<Search.SearchResultUpdateSignal> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    private func apply(searchQuery: Search.SearchQuery, for nodes: [NodeEntity]) -> Search.SearchResultsEntity {
        switch searchQuery {
        case .initial:
            let results = nodes.map { folderSearchResultMapper.mapToSearchResult(from: $0) }
            return SearchResultsEntity(results: results, availableChips: [], appliedChips: [])
        case let .userSupplied(queryEntity):
            let textQuery = queryEntity.query
            let results = if textQuery.isEmpty {
                nodes.map { folderSearchResultMapper.mapToSearchResult(from: $0) }
            } else {
                nodes
                    .filter { $0.name.containsIgnoringCaseAndDiacritics(searchText: textQuery) }
                    .map { folderSearchResultMapper.mapToSearchResult(from: $0) }
            }
            return SearchResultsEntity(results: results, availableChips: [], appliedChips: [])
        }
    }
}

extension SearchResultsEntity {
    static var empty: SearchResultsEntity {
        SearchResultsEntity(results: [], availableChips: [], appliedChips: [])
    }
}
