import MEGASwift
import Search

struct FavouriteSearchResultsProvider: SearchResultsProviding {
    func refreshedSearchResults(queryRequest: Search.SearchQuery) async throws -> SearchResultsEntity? {
        .init(results: [], availableChips: [], appliedChips: [])
    }

    func search(queryRequest: Search.SearchQuery, lastItemIndex: Int?) async -> SearchResultsEntity? {
        .init(results: [], availableChips: [], appliedChips: [])
    }

    func currentResultIds() -> [Search.ResultId] {
        []
    }

    func searchResultUpdateSignalSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        EmptyAsyncSequence<SearchResultUpdateSignal>().eraseToAnyAsyncSequence()
    }
}
