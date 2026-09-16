import Foundation
import Observation
@preconcurrency import PDFKit

@Observable
@MainActor
final class PDFViewerViewModel {
    struct Dependency {
        let pdfDocumentSource: PDFViewerDocumentSource
        let documentURLUseCase: any PDFDocumentURLUseCaseProtocol
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
        let events = dependency.documentURLUseCase.localDocumentURL(for: dependency.pdfDocumentSource)
        do {
            for try await event in events {
                guard !Task.isCancelled else { return }
                switch event {
                case .progress(let progress):
                    state = .loading(progress: progress)
                case .ready(let url):
                    loadDocument(at: url)
                }
            }
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed
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
