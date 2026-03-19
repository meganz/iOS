import MEGADomain
import MEGASwift
import Search

struct RecentActionBucketItemsProvider: SearchResultsProviding {
    private let bucket: RecentActionBucketEntity
    private let resultMapper: any RecentActionBucketItemResultMapping
    
    init(bucket: RecentActionBucketEntity, resultMapper: any RecentActionBucketItemResultMapping) {
        self.bucket = bucket
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
            results: bucket.nodes.map { resultMapper.map(node: $0) },
            availableChips: [],
            appliedChips: []
        )
    }
    
    func currentResultIds() -> [Search.ResultId] {
        bucket.nodes.map(\.handle)
    }
    
    func searchResultUpdateSignalSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
}
