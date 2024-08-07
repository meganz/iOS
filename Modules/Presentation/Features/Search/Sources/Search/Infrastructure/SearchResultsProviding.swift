// Main interface used to execute searches

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
    
    /// Listen to `.specific` result updates. This is a temporary solution for handling updates for newly downloaded nodes.
    /// Can be better implemented using async sequence with [SAO-1507]
    func listenToSpecificResultUpdates() async
}
