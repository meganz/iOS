// Main interface used to execute searches
public protocol SearchResultsProviding {
    func search(queryRequest: SearchQueryEntity) async throws -> SearchResultsEntity
}
