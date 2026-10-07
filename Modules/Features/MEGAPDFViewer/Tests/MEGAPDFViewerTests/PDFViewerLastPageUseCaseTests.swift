import Foundation
@testable import MEGAPDFViewer
import Testing

@MainActor
struct PDFViewerLastPageUseCaseTests {
    private let url = URL(fileURLWithPath: "/tmp/test.pdf")

    @Test func documentIdentifierForLastViewedPageIndex_returnsFingerprint() async {
        let (sut, _) = makeSUT(fingerprint: "abc")

        #expect(await sut.documentIdentifierForLastViewedPageIndex(forDocumentAt: url) == "abc")
    }

    @Test func documentIdentifierForLastViewedPageIndex_whenFingerprintIsNil_returnsNil() async {
        let (sut, _) = makeSUT(fingerprint: nil)

        #expect(await sut.documentIdentifierForLastViewedPageIndex(forDocumentAt: url) == nil)
    }

    @Test func documentIdentifierForLastViewedPageIndex_whenFingerprintIsEmpty_returnsNil() async {
        let (sut, _) = makeSUT(fingerprint: "")

        #expect(await sut.documentIdentifierForLastViewedPageIndex(forDocumentAt: url) == nil)
    }

    @Test func loadLastPageIndex_forwardsIdentifierToRepository() async {
        let (sut, repository) = makeSUT(fingerprint: "abc", storedIndex: 7)

        let index = await sut.loadLastPageIndex(forDocumentIdentifier: "abc")

        #expect(index == 7)
        #expect(repository.invocations == [.loadLastPageIndex(documentIdentifier: "abc")])
    }

    @Test func saveLastPageIndex_whenSecondOrLaterPage_savesToRepository() async {
        let (sut, repository) = makeSUT(fingerprint: "abc")

        await sut.saveLastPageIndex(3, forDocumentIdentifier: "abc")

        #expect(repository.invocations == [
            .saveLastPageIndex(index: 3, documentIdentifier: "abc")
        ])
    }

    @Test(arguments: [0, -1])
    func saveLastPageIndex_whenFirstPageOrBefore_deletesFromRepository(index: Int) async {
        let (sut, repository) = makeSUT(fingerprint: "abc")

        await sut.saveLastPageIndex(index, forDocumentIdentifier: "abc")

        #expect(repository.invocations == [.deleteLastPageIndex(documentIdentifier: "abc")])
    }

    private func makeSUT(
        fingerprint: String?,
        storedIndex: Int? = nil
    ) -> (
        sut: PDFViewerLastPageUseCase,
        repository: MockPDFViewerLastPageRepository
    ) {
        let repository = MockPDFViewerLastPageRepository(loadLastPageIndexResult: storedIndex)
        let sut = PDFViewerLastPageUseCase(
            repository: repository,
            fingerprintRepository: MockPDFViewerDocumentFingerprintRepository(
                fingerprintResult: fingerprint
            )
        )
        return (sut, repository)
    }
}
