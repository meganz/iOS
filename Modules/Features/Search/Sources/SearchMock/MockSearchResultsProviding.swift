import Search

public class MockSearchResultsProviding: SearchResultsProviding {
    
    public var passedInQueries: [SearchQueryEntity] = []
    public var resultFactory: (_ query: SearchQueryEntity) async throws -> SearchResultsEntity
    
    public init() {
        resultFactory = { _ in
            .defaultTestResult
        }
    }
    
    public func search(
        query: SearchQueryEntity
    ) async throws -> SearchResultsEntity {
        passedInQueries.append(query)
        return try await resultFactory(query)
    }
}

extension SearchResultsEntity {
    static var defaultTestResult: Self {
        .init(
            results: [.resultWith(id: "1")],
            chips: [.chipWith(id: "2")]
        )
    }
}

extension SearchResult {
    static func resultWith(id: ResultId) -> Self {
        .init(
            id: id,
            title: "title_\(id)",
            description: "subtitle_\(id)",
            properties: [],
            thumbnailImageData: { .init() },
            menuBuilder: {
                .init()
            },
            type: .node
        )
    }
}

extension SearchChipEntity {
    static func chipWith(id: ChipId) -> Self {
        .init(
            id: id,
            title: "chip_\(id)",
            icon: nil
        )
    }
}
