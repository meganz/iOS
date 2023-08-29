import SwiftUI

public struct SearchResultsView: View {
    private let results: [SearchResult]

    public init(with results: [SearchResult]) {
        self.results = results
    }

    public var body: some View {
        List {
            ForEach(results) {
                SearchResultRowView(
                    viewModel: .init(with: $0)
                )
            }
        }
        .listStyle(.plain)
    }
}

struct SearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        let id = ResultId(id: "1")
        let searchResult = SearchResult(
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


        return SearchResultsView(
            with: [
                searchResult,
                searchResult,
                searchResult
            ]
        )
    }
}
