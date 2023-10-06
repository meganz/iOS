// Main interface used to execute searches

public protocol SearchResultsProviding {
    func search(queryRequest: SearchQuery, lastItemIndex: Int?) async throws -> SearchResultsEntity?
}
