// Main interface used to execute searches

public protocol SearchResultsProviding {
    
    func search(queryRequest: SearchQuery, lastItemIndex: Int?) async -> SearchResultsEntity?
    // ids of all siblings a of a node (for initial [root] search)
    // or
    // ids of all results in the current search results
    // needed due to:
    // * paging in the image gallery
    // * audio player
    // * select all functionality
    func currentResultIds() -> [ResultId]
}
