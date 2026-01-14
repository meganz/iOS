@testable import Search

final class MockSearchResultsInteractor: SearchResultsInteractor {
    var viewMode: SearchResultsViewMode = .list

    var currentViewMode: SearchResultsViewMode {
        viewMode
    }

    func resetLastAvailableChips() {}

    func updateQuery(_ currentQuery: SearchQuery) -> SearchQuery {
        currentQuery
    }

    func consume(results: SearchResultsEntity) {}

    func listItemsUpdated(_ items: [SearchResultRowViewModel]) {}
}
