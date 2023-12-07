import Search

public class MockSearchResultsProviding: SearchResultsProviding {
    public var passedInQueries: [SearchQuery] = []
    public var resultFactory: (_ query: SearchQuery) async throws -> SearchResultsEntity
    
    public init() {
        resultFactory = { _ in
            .resultWithNoItemsAndSingleChip
        }
    }

    public func search(
        queryRequest: SearchQuery,
        lastItemIndex: Int?
    ) async throws -> SearchResultsEntity? {
        passedInQueries.append(queryRequest)
        return try await resultFactory(queryRequest)
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
            type: .nodeFormat(id),
            title: "chip_\(id)",
            icon: nil
        )
    }
}
