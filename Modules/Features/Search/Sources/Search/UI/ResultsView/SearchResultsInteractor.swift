import Foundation

@MainActor
protocol SearchResultsInteractor: AnyObject {
    var currentViewMode: SearchResultsViewMode { get }
    func resetLastAvailableChips()
    func updateQuery(_ currentQuery: SearchQuery) -> SearchQuery
    func consume(results: SearchResultsEntity)
    func listItemsUpdated(_ items: [SearchResultRowViewModel])
}
