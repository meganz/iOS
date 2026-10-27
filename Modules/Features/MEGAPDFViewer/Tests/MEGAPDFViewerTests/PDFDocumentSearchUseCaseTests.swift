@testable import MEGAPDFViewer
import Testing

@MainActor
struct PDFDocumentSearchUseCaseTests {
    @Test(arguments: ["tes", "ab👍"])
    func shortQuery_finishesWithoutSearching(query: String) async {
        let searcher = MockPDFDocumentSearcher()
        let sut = PDFDocumentSearchUseCase(documentSearcher: searcher)
        var matchCount = 0

        for await _ in sut.matches(for: query, compareOptions: []) {
            matchCount += 1
        }

        #expect(matchCount == 0)
        #expect(searcher.searches.isEmpty)
    }

    @Test func queryOfFourCharacters_searchesWithItsCompareOptions() {
        let searcher = MockPDFDocumentSearcher()
        let sut = PDFDocumentSearchUseCase(documentSearcher: searcher)

        _ = sut.matches(for: "test", compareOptions: .caseInsensitive)

        #expect(searcher.searches == [.init(query: "test", compareOptions: .caseInsensitive)])
    }
}
