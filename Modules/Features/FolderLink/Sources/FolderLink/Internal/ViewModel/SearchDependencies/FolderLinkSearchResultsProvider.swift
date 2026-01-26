import MEGADomain
import MEGASwift
import Search

struct FolderLinkSearchResultsProvider: SearchResultsProviding {
    private let nodeHandle: HandleEntity
    private let searchChips: [SearchChipEntity]
    private let folderLinkSearchUseCase: any FolderLinkSearchUseCaseProtocol
    private let folderSearchResultMapper: any FolderLinkSearchResultMapperProtocol
    @Atomic private var allResultIds: [ResultId] = []
    
    init(
        nodeHandle: HandleEntity,
        searchChips: [SearchChipEntity],
        folderLinkSearchUseCase: some FolderLinkSearchUseCaseProtocol,
        folderSearchResultMapper: some FolderLinkSearchResultMapperProtocol
    ) {
        self.nodeHandle = nodeHandle
        self.searchChips = searchChips
        self.folderLinkSearchUseCase = folderLinkSearchUseCase
        self.folderSearchResultMapper = folderSearchResultMapper
    }
    
    func refreshedSearchResults(queryRequest: Search.SearchQuery) async throws -> Search.SearchResultsEntity? {
        await search(queryRequest: queryRequest, lastItemIndex: nil)
    }
    
    func search(queryRequest: Search.SearchQuery, lastItemIndex: Int?) async -> Search.SearchResultsEntity? {
        let appliedChips = queryRequest == .initial ? [] : queryRequest.chips
        
        if lastItemIndex != nil {
            return SearchResultsEntity(results: [], availableChips: searchChips, appliedChips: appliedChips)
        }
        
        do {
            let children = try await folderLinkSearchUseCase.search(parentHandle: nodeHandle, with: queryRequest)
            let results = children.map { folderSearchResultMapper.mapToSearchResult(from: $0) }
            let searchResultEntity = SearchResultsEntity(results: results, availableChips: searchChips, appliedChips: appliedChips)
            $allResultIds.mutate { $0 = results.map(\.id) }
            return searchResultEntity
        } catch {
            return nil
        }
    }
    
    func currentResultIds() -> [Search.ResultId] {
        allResultIds
    }
    
    func searchResultUpdateSignalSequence() -> MEGASwift.AnyAsyncSequence<Search.SearchResultUpdateSignal> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
}
