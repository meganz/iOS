import Foundation

@MainActor
protocol SearchResultsInteractor: AnyObject {
    func resetLastAvailableChips()
    func updateQuery(_ currentQuery: SearchQuery) async -> SearchQuery
    func consume(results: SearchResultsEntity)
    func listItemsUpdated(_ items: [SearchResultRowViewModel])
}
