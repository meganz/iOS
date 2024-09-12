import MEGADomain
import MEGASdk
import MEGASwift
import Search

struct RecentActionBucketProvider: SearchResultsProviding {
    func searchResultUpdateSignalSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    func refreshedSearchResults(queryRequest: Search.SearchQuery) async throws -> Search.SearchResultsEntity? {
        // To be addressed in [SAO-1273]
        nil
    }
    
    func currentResultIds() -> [Search.ResultId] {
        guard let list = bucket.nodesList else { return [] }
        return list.toNodeArray().map {
            $0.handle
        }
    }
    
    var bucket: MEGARecentActionBucket
    var mapper: SearchResultMapper
    
    func search(
        queryRequest: SearchQuery,
        lastItemIndex: Int?
    ) async -> SearchResultsEntity? {
        switch queryRequest {
        case .initial:
                all
        case .userSupplied(let queryEntity):
            filtered(queryEntity)
        }
    }
    
    var allBucketResults: [SearchResult] {
        nodeEntities().map(mapper.map(node:))
    }
    
    func nodeEntities(_ queryEntity: SearchQueryEntity? = nil) -> [NodeEntity] {
        let list = bucket.nodesList?.toNodeEntities() ?? []
        guard let queryEntity else {
            return list // return all when no query
        }
        
        // if query, just filter with name
        let queryLowercased = queryEntity.query.lowercased()
        return list.filter {
            $0.name.lowercased().contains(queryLowercased)
        }
    }
    
    var all: SearchResultsEntity {
        .init(
            results: allBucketResults,
            availableChips: [],
            appliedChips: []
        )
    }
    
    func filtered(_ queryEntity: SearchQueryEntity) -> SearchResultsEntity {
        .init(
            results: [], // need to use code in mapNodeToSearchResult
            availableChips: [],
            appliedChips: []
        )
    }
}
