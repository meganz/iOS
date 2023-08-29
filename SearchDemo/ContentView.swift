import SwiftUI
import Search

struct ContentView: View {
    let searchResult = SearchResult(
        id: ResultId(stringLiteral: "1"),
        title: "title_1",
        description: "subtitle_1)",
        properties: [],
        thumbnailImageData: { .init() },
        menuBuilder: {
            .init()
        },
        type: .node
    )

    var body: some View {
        SearchResultsView(
            with: [searchResult, searchResult, searchResult]
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
