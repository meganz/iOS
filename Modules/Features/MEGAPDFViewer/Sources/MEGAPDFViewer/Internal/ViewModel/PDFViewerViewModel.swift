import Foundation
import MEGAL10n
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
        struct PagingState: Equatable {
            var currentPageIndex: Int
            var pageCount: Int
        }

        case loading(progress: Float?)
        case ready(document: PDFDocument, pagingState: PagingState)
        case failed

        var isReady: Bool {
            switch self {
            case .ready: true
            default: false
            }
        }
    }

    private(set) var state: ViewState = .loading(progress: nil)

    private let dependency: Dependency

    var fileName: String { dependency.fileName }

    init(dependency: Dependency) {
        self.dependency = dependency
    }
}

// MARK: - Document loading

extension PDFViewerViewModel {

    /// Held here rather than inside `PDFDisplayerView` for future MR:
    /// The thumbnails grid will render from the same loaded document.
    var pdfDocument: PDFDocument? {
        guard case .ready(let document, _) = state else { return nil }
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
        let pagingState = ViewState.PagingState(currentPageIndex: 0, pageCount: document.pageCount)
        state = .ready(document: document, pagingState: pagingState)
    }
}

// MARK: - Paging state management

extension PDFViewerViewModel {

    private var pagingState: ViewState.PagingState? {
        get {
            guard case .ready(_, let pagingState) = state else { return nil }
            return pagingState
        }
        set {
            guard let newValue, case .ready(let document, _) = state else { return }
            state = .ready(document: document, pagingState: newValue)
        }
    }

    var currentPageIndex: Int {
        get { pagingState?.currentPageIndex ?? 0 }
        set {
            guard let pageCount = pagingState?.pageCount,
                  (0..<pageCount).contains(newValue) else { return }
            pagingState?.currentPageIndex = newValue
        }
    }

    var pageIndicatorText: String {
        guard case .ready(_, let pagingState) = state else { return "" }
        return Strings.Localizable.PdfPreview.pageOfTotal(
            pagingState.currentPageIndex + 1,
            pagingState.pageCount
        )
    }
}
