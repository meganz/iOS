import Foundation
import Observation
@preconcurrency import PDFKit

@Observable
@MainActor
final class PDFViewerViewModel {
    struct Dependency {
        let pdfDocumentSource: PDFViewerDocumentSource
        let documentLoader: any PDFDocumentLoading
        let fileName: String
    }

    enum ViewState: Equatable {
        case loading(progress: Float?)
        case ready(document: PDFDocument)
        case failed
    }

    private(set) var state: ViewState = .loading(progress: nil)

    private let dependency: Dependency

    init(dependency: Dependency) {
        self.dependency = dependency
    }
}

// MARK: - Document loading

extension PDFViewerViewModel {

    /// Held here rather than inside `PDFDisplayerView` for future MR:
    /// The thumbnails grid will render from the same loaded document.
    var pdfDocument: PDFDocument? {
        guard case .ready(let document) = state else { return nil }
        return document
    }

    /// Resolves the source to a file on disk and parses it. Re-entrant by
    /// design: SwiftUI restarts `.task` on every appearance, and a document
    /// already parsed is not resolved again.
    func loadDocumentFromSource() async {
        guard pdfDocument == nil else { return }
        // Loading from a `MEGANode` will be added in an upcoming MR.
        switch dependency.pdfDocumentSource {
        case .local(let url):
            loadDocument(at: url)
        }
    }

    private func loadDocument(at url: URL) {
        guard let document = dependency.documentLoader.loadDocument(url: url) else {
            state = .failed
            return
        }
        state = .ready(document: document)
    }
}
