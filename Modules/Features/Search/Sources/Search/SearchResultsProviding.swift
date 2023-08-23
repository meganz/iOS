// Main interface used to execute searches
public protocol SearchResultsProviding {
    func search(query: SearchQueryEntity) async throws -> SearchResultsEntity
}
