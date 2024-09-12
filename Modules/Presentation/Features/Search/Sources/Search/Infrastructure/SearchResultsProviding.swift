import MEGASwift

// Signal for search results updates
public enum SearchResultUpdateSignal: Sendable, Equatable {
    case generic // A generic update in the results (e.g: multiple file changes, etc..) and client will need to refresh the whole result list.
    case specific(result: SearchResult) // Update from a specific result, client only needs to update the item for that result
}

/// Main interface used to execute searches
public protocol SearchResultsProviding {

    /// Get the most updated results from data source according to a queryRequest
    func refreshedSearchResults(queryRequest: SearchQuery) async throws -> SearchResultsEntity?

    func search(queryRequest: SearchQuery, lastItemIndex: Int?) async -> SearchResultsEntity?
    // ids of all siblings a of a node (for initial [root] search)
    // or
    // ids of all results in the current search results
    // needed due to:
    // * paging in the image gallery
    // * audio player
    // * select all functionality
    func currentResultIds() -> [ResultId]
    
    /// Async Sequence that signals for search result updates
    /// - Returns: AnyAsyncSequence<SearchResultUpdateSignal> to indicate what type of update needs to occur.
    func searchResultUpdateSignalSequence() -> AnyAsyncSequence<SearchResultUpdateSignal>
}
