import MEGADomain
import MEGASwift
import Search

struct RecentActionBucketItemsProvider: SearchResultsProviding {
    private let nodes: [NodeEntity]
    private let resultMapper: any RecentActionBucketItemResultMapping
    
    init(nodes: [NodeEntity], resultMapper: any RecentActionBucketItemResultMapping) {
        self.nodes = nodes
        self.resultMapper = resultMapper
    }
    
    func refreshedSearchResults(queryRequest: Search.SearchQuery) async throws -> Search.SearchResultsEntity? {
        await search(queryRequest: queryRequest, lastItemIndex: nil)
    }
    
    func search(queryRequest: Search.SearchQuery, lastItemIndex: Int?) async -> Search.SearchResultsEntity? {
        guard lastItemIndex == nil else {
            return SearchResultsEntity(results: [], availableChips: [], appliedChips: [])
        }
        
        return SearchResultsEntity(
            results: nodes.map { resultMapper.map(node: $0) },
            availableChips: [],
            appliedChips: []
        )
    }
    
    func currentResultIds() -> [Search.ResultId] {
        nodes.map(\.handle)
    }
    
    func searchResultUpdateSignalSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
}
