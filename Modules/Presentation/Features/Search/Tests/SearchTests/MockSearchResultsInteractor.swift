@testable import Search

final class MockSearchResultsInteractor: SearchResultsInteractor {
    func resetLastAvailableChips() {}

    func updateQuery(_ currentQuery: SearchQuery) async -> SearchQuery {
        currentQuery
    }

    func consume(results: SearchResultsEntity) {}

    func listItemsUpdated(_ items: [SearchResultRowViewModel]) {}
}
