import Search
import MEGASdk

struct RecentActionBucketProvider: SearchResultsProviding {
    var bucket: MEGARecentActionBucket
    func search(queryRequest: SearchQuery, lastItemIndex: Int?) async throws -> SearchResultsEntity? {
        .init(
            results: [], // need to use code in mapNodeToSearchResult
            availableChips: [],
            appliedChips: []
        )
    }
}
