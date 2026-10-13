import Foundation
import PDFKit
@testable import MEGAPDFViewer

actor MockPDFOutlineReader: PDFOutlineReading {
    private let items: PDFOutlineItems
    private(set) var requestedURLs: [URL] = []

    init(items: PDFOutlineItems = PDFOutlineItems(
        inOutlineOrder: [], inPageOrder: []
    )) {
        self.items = items
    }

    nonisolated func shouldLoadOutline(document: PDFDocument) -> Bool {
        (document.outlineRoot?.numberOfChildren ?? 0) > 0
    }

    func outlineItems(
        forDocumentAt url: URL,
        documentLoader: some PDFDocumentLoading
    ) -> PDFOutlineItems {
        requestedURLs.append(url)
        return items
    }
}
