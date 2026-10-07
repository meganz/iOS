import Foundation
@testable import MEGAPDFViewer
import PDFKit
import Testing

@MainActor
struct PDFViewerDocumentLoadingUseCaseTests {
    private let url = URL(fileURLWithPath: "/tmp/test.pdf")

    @Test func loadDocument_whenParsingFails_returnsFailedWithoutIdentifying() async throws {
        let lastPageUseCase = MockPDFViewerLastPageUseCase()
        let sut = makeSUT(document: nil, lastPageUseCase: lastPageUseCase)

        let isFailed = switch try await sut.loadDocument(at: url) {
        case .failed: true
        case .ready: false
        }

        #expect(isFailed)
        #expect(lastPageUseCase.invocations.isEmpty)
    }

    @Test func loadDocument_whenIdentified_carriesIdentifierAndResumePage() async throws {
        let lastPageUseCase = MockPDFViewerLastPageUseCase(
            documentIdentifierForLastViewedPageIndexResult: "abc",
            loadLastPageIndexResult: 4
        )
        let sut = makeSUT(lastPageUseCase: lastPageUseCase)

        guard case .ready(let readyState) = try await sut.loadDocument(at: url) else {
            Issue.record("Expected .ready")
            return
        }

        #expect(readyState.documentIdentifierForLastViewedPageIndex == "abc")
        #expect(readyState.initialPageIndex == 4)
        #expect(lastPageUseCase.invocations == [
            .documentIdentifierForLastViewedPageIndex(url: url),
            .loadLastPageIndex(documentIdentifier: "abc")
        ])
    }

    @Test func loadDocument_whenNotIdentified_skipsResumePageLookup() async throws {
        let lastPageUseCase = MockPDFViewerLastPageUseCase(
            documentIdentifierForLastViewedPageIndexResult: nil,
            loadLastPageIndexResult: 4
        )
        let sut = makeSUT(lastPageUseCase: lastPageUseCase)

        guard case .ready(let readyState) = try await sut.loadDocument(at: url) else {
            Issue.record("Expected .ready")
            return
        }

        #expect(readyState.documentIdentifierForLastViewedPageIndex == nil)
        #expect(readyState.initialPageIndex == nil)
        #expect(lastPageUseCase.invocations == [.documentIdentifierForLastViewedPageIndex(url: url)])
    }

    @Test func loadDocument_whenCancelled_throwsBeforeResumePageLookup() async {
        let lastPageUseCase = MockPDFViewerLastPageUseCase(documentIdentifierForLastViewedPageIndexResult: "abc")
        let sut = makeSUT(lastPageUseCase: lastPageUseCase)

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await sut.loadDocument(at: url)
        }

        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(lastPageUseCase.invocations == [.documentIdentifierForLastViewedPageIndex(url: url)])
    }

    private func makeSUT(
        document: PDFDocument? = MockPDFDocumentLoader.makeDocument(),
        lastPageUseCase: MockPDFViewerLastPageUseCase
    ) -> PDFViewerDocumentLoadingUseCase {
        PDFViewerDocumentLoadingUseCase(
            documentLoader: MockPDFDocumentLoader(document: document),
            lastPageUseCase: lastPageUseCase
        )
    }
}
