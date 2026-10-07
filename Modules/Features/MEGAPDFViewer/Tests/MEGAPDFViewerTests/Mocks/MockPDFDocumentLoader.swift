import Foundation
@testable import MEGAPDFViewer
import PDFKit

struct MockPDFDocumentLoader: PDFDocumentLoading, @unchecked Sendable {
    let document: PDFDocument?

    func loadDocument(url: URL) -> PDFDocument? {
        document
    }

    /// Blank pages, so the loader mock can return something real.
    static func makeDocument(pageCount: Int = 1) -> PDFDocument {
        let document = PDFDocument()
        for index in 0..<pageCount {
            document.insert(PDFPage(), at: index)
        }
        return document
    }
}
