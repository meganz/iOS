import MEGASwift
import Search

public class MockSearchResultsProviding: SearchResultsProviding {
    
    public var refreshedSearchResultsToReturn: Search.SearchResultsEntity?
    public func refreshedSearchResults(queryRequest: Search.SearchQuery) async throws -> Search.SearchResultsEntity? {
        refreshedSearchResultsToReturn
    }
    
    public func currentResultIds() -> [Search.ResultId] {
        currentResultIdsToReturn
    }
    
    private let _searchResultUpdateSignalSequence: AnyAsyncSequence<SearchResultUpdateSignal>
    public var passedInQueries: [SearchQuery] = []
    public var currentResultIdsToReturn: [ResultId] = []
    public var resultFactory: (_ query: SearchQuery) async -> SearchResultsEntity?
    
    public init(
        searchResultUpdateSignalSequence: AnyAsyncSequence<SearchResultUpdateSignal> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        resultFactory = { _ in
            .resultWithNoItemsAndSingleChip
        }
        _searchResultUpdateSignalSequence = searchResultUpdateSignalSequence
    }

    public func search(
        queryRequest: SearchQuery,
        lastItemIndex: Int?
    ) async -> SearchResultsEntity? {
        passedInQueries.append(queryRequest)
        return await resultFactory(queryRequest)
    }
    
    public func searchResultUpdateSignalSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        _searchResultUpdateSignalSequence
    }
}

extension SearchResultsEntity {
    public static var resultWithSingleItemAndChip: Self {
        .init(
            results: [.resultWith(id: 1)],
            availableChips: [.chipWith(id: 2)],
            appliedChips: []
        )
    }
    public static var resultWithNoItemsAndSingleChip: Self {
        .init(
            results: [],
            availableChips: [.chipWith(id: 2)],
            appliedChips: []
        )
    }
}

extension SearchChipEntity {
    public static func chipWith(id: Int) -> Self {
        .init(
            type: .nodeFormat(.photo),
            title: "chip_\(id)",
            icon: nil
        )
    }
}
