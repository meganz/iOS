import Foundation
import PDFKit

protocol PDFDocumentLoading {
    /// Returns nil when PDFKit cannot parse the file.
    func loadDocument(url: URL) -> PDFDocument?
}

struct PDFDocumentLoader: PDFDocumentLoading {
    func loadDocument(url: URL) -> PDFDocument? {
        PDFDocument(url: url)
    }
}
