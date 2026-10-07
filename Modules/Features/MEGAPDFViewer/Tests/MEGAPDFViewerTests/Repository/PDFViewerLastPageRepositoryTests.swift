@testable import MEGAPDFViewer
import Testing

@MainActor
struct PDFViewerLastPageRepositoryTests {

    @Test("no stored destination returns nil")
    func loadLastPageIndex_whenNoStoredDestination_returnsNil() async {
        let (sut, _) = makeSUT(fetchLastPageDestinationResult: nil)

        #expect(await sut.loadLastPageIndex(forDocumentIdentifier: "any-identifier") == nil)
    }

    @Test("stored destination on first page returns nil")
    func loadLastPageIndex_whenStoredDestinationIsFirstPage_returnsNil() async {
        let (sut, _) = makeSUT(fetchLastPageDestinationResult: 1)

        #expect(await sut.loadLastPageIndex(forDocumentIdentifier: "any-identifier") == nil)
    }

    @Test("stored destination on a later page returns its zero-based index")
    func loadLastPageIndex_whenStoredDestinationIsLaterPage_returnsZeroBasedIndex() async {
        let (sut, _) = makeSUT(fetchLastPageDestinationResult: 8)

        #expect(await sut.loadLastPageIndex(forDocumentIdentifier: "any-identifier") == 7)
    }

    @Test("delete removes the stored destination")
    func deleteLastPageIndex_deletesStoredDestination() async {
        let (sut, store) = makeSUT()

        await sut.deleteLastPageIndex(forDocumentIdentifier: "any-identifier")

        #expect(store.invocations == [.deleteLastPageDestination(fingerprint: "any-identifier")])
    }

    @Test("save stores the one-based destination")
    func saveLastPageIndex_savesOneBasedDestination() async {
        let (sut, store) = makeSUT()

        await sut.saveLastPageIndex(7, forDocumentIdentifier: "any-identifier")

        #expect(store.invocations == [.saveLastPageDestination(destination: 8, fingerprint: "any-identifier")])
    }

    private func makeSUT(
        fetchLastPageDestinationResult: Int? = nil
    ) -> (
        sut: PDFViewerLastPageRepository,
        store: MockPDFViewerLastPageMEGAStore
    ) {
        let store = MockPDFViewerLastPageMEGAStore(fetchLastPageDestinationResult: fetchLastPageDestinationResult)
        let sut = PDFViewerLastPageRepository(store: store)
        return (sut, store)
    }
}
