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

        struct FailedState: Equatable {
            var failureReason: FailureReason
            var isShowingDamagedFileAlert: Bool

            init(
                _ failureReason: FailureReason,
                isShowingDamagedFileAlert: Bool = false
            ) {
                self.failureReason = failureReason
                self.isShowingDamagedFileAlert = isShowingDamagedFileAlert
            }
        }

        enum FailureReason: Equatable {
            case downloadFailed
            case documentUnreadable
        }

        case loading(progress: Float?)
        case ready(document: PDFDocument, pagingState: PagingState)
        case failed(FailedState)

        var isReady: Bool {
            switch self {
            case .ready: true
            default: false
            }
        }

        var isFailed: Bool { if case .failed = self { true } else { false } }
    }

    private(set) var state: ViewState = .loading(progress: nil)
    private(set) var thumbnailLoader: (any PDFThumbnailLoading)?

    private var failedState: ViewState.FailedState? {
        get { if case .failed(let failedState) = state { failedState } else { nil } }
        set { if let newValue, state.isFailed { state = .failed(newValue) } }
    }

    var isChromeHidden = false
    var isShowingThumbnails = false

    private let dependency: Dependency

    var fileName: String { dependency.fileName }

    init(dependency: Dependency) {
        self.dependency = dependency
    }
}

// MARK: - Document loading

extension PDFViewerViewModel {

    /// The instance `MEGAPDFView` draws from; nil until a parse succeeds.
    /// Thumbnails render from a separate instance, see `loadDocument(at:)`.
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
            fail(.downloadFailed)
        }
    }

    private func loadDocument(at url: URL) {
        guard let document = dependency.documentLoader.loadDocument(url: url) else {
            fail(.documentUnreadable)
            return
        }
        let pagingState = ViewState.PagingState(currentPageIndex: 0, pageCount: document.pageCount)
        // Thumbnails render off the main thread, so they parse their own
        // instance rather than sharing the one `MEGAPDFView` draws from.
        if let thumbnailDocument = dependency.documentLoader.loadDocument(url: url) {
            thumbnailLoader = PDFThumbnailLoader(document: thumbnailDocument)
        }
        state = .ready(document: document, pagingState: pagingState)
    }

    private func fail(_ reason: ViewState.FailureReason) {
        isChromeHidden = false
        state = .failed(
            .init(reason,
                  isShowingDamagedFileAlert: reason == .documentUnreadable)
        )
    }
}

// MARK: - Failure state management

extension PDFViewerViewModel {
    var isShowingDamagedFileAlert: Bool {
        get { failedState?.isShowingDamagedFileAlert ?? false }
        set { failedState?.isShowingDamagedFileAlert = newValue }
    }

    /// Returns to the loading state and resolves the source again.
    func retryDocumentLoad() async {
        state = .loading(progress: nil)
        await loadDocumentFromSource()
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
