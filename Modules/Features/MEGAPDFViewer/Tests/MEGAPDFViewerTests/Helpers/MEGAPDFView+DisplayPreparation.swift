@testable import MEGAPDFViewer
import PDFKit
import Testing

@MainActor
final class DisplayPreparationSpy: MEGAPDFViewPageObservationDelegate {
    private(set) var preparedCount = 0

    func pdfView(_ pdfView: MEGAPDFView, currentPageDidChange index: Int) {}

    func pdfView(_ pdfView: MEGAPDFView, isScrolledToTopDidChange isScrolledToTop: Bool) {}

    func pdfViewDidFinishPreparingForDisplayAndInteraction(_ pdfView: MEGAPDFView) {
        preparedCount += 1
    }
}

extension MEGAPDFView {
    /// Configures `document` and returns once the view reports its display
    /// prepared, recording an issue if that does not happen within `timeout`.
    @discardableResult
    func configureAndAwaitDisplayPreparation(
        document: PDFDocument,
        timeout: Duration = .seconds(3)
    ) async throws -> DisplayPreparationSpy {
        let spy = DisplayPreparationSpy()
        pageObservationDelegate = spy
        configure(document: document)
        let deadline = ContinuousClock.now + timeout
        while spy.preparedCount == 0, ContinuousClock.now < deadline {
            layoutIfNeeded()
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(spy.preparedCount == 1, "MEGAPDFView did not report its display prepared")
        for _ in 0..<3 { layoutIfNeeded() }
        return spy
    }
}
