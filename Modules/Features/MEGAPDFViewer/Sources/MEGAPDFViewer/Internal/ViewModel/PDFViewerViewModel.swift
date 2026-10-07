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
        let documentLoadingUseCase: any PDFViewerDocumentLoadingUseCaseProtocol
        let lastPageUseCase: any PDFViewerLastPageUseCaseProtocol
        let fileName: String
        let onMoreTapped: (@MainActor () -> Void)?
    }

    enum ViewState: Equatable {
        struct ReadyState: Equatable {
            struct PagingState: Equatable {
                var currentPageIndex: Int
                var pageCount: Int
            }

            let document: PDFDocument
            var pagingState: PagingState
            let documentIdentifierForLastViewedPageIndex: String?
            let initialPageIndex: Int?
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
        case ready(ReadyState)
        case failed(FailedState)

        var isReady: Bool { if case .ready = self { true } else { false } }

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
    var isProgrammaticallyScrollingToCurrentPage = false
    @ObservationIgnored private var isScrolledToTop = false
    @ObservationIgnored private var didApplyInitialPageNavigation = false

    private let dependency: Dependency

    var fileName: String { dependency.fileName }

    var showsMoreButton: Bool {
        dependency.onMoreTapped != nil && !state.isFailed
    }

    private var readyState: ViewState.ReadyState? {
        get { if case .ready(let readyState) = state { readyState } else { nil } }
        set { if let newValue, state.isReady { state = .ready(newValue) } }
    }

    init(dependency: Dependency) {
        self.dependency = dependency
    }

    func didTapMore() {
        dependency.onMoreTapped?()
    }
}

// MARK: - Document loading

extension PDFViewerViewModel {

    /// The instance `MEGAPDFView` draws from; nil until a parse succeeds.
    /// Thumbnails render from a separate instance, see
    /// `PDFViewerDocumentLoadingUseCase`.
    var pdfDocument: PDFDocument? {
        readyState?.document
    }

    var initialPageIndex: Int? {
        readyState?.initialPageIndex
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
                    try await loadDocument(at: url)
                }
            }
        } catch {
            guard !Task.isCancelled else { return }
            fail(.downloadFailed)
        }
    }

    private func loadDocument(at url: URL) async throws {
        let loadingState = try await dependency.documentLoadingUseCase.loadDocument(at: url)
        switch loadingState {
        case .failed:
            fail(.documentUnreadable)
        case .ready(let readyState):
            if let thumbnailDocument = readyState.thumbnailDocument {
                thumbnailLoader = PDFThumbnailLoader(document: thumbnailDocument)
            }
            state = .ready(ViewState.ReadyState(
                document: readyState.document,
                pagingState: ViewState.ReadyState.PagingState(
                    currentPageIndex: 0,
                    pageCount: readyState.document.pageCount
                ),
                documentIdentifierForLastViewedPageIndex:
                    readyState.documentIdentifierForLastViewedPageIndex,
                initialPageIndex: readyState.initialPageIndex
            ))
        }
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

    var currentPageIndex: Int {
        get { readyState?.pagingState.currentPageIndex ?? 0 }
        set {
            guard let pageCount = readyState?.pagingState.pageCount,
                  (0..<pageCount).contains(newValue) else { return }
            readyState?.pagingState.currentPageIndex = newValue
        }
    }

    var pageIndicatorText: String {
        guard let pagingState = readyState?.pagingState else { return "" }
        return Strings.Localizable.PdfPreview.pageOfTotal(
            pagingState.currentPageIndex + 1,
            pagingState.pageCount
        )
    }

    func didSelectThumbnail(at pageIndex: Int) {
        scrollToPageIndex(pageIndex)
        isShowingThumbnails = false
    }

    private func scrollToPageIndex(_ pageIndex: Int) {
        guard let pageCount = readyState?.pagingState.pageCount,
              (0..<pageCount).contains(pageIndex) else { return }
        currentPageIndex = pageIndex
        isProgrammaticallyScrollingToCurrentPage = true
    }
}

// MARK: - Save

extension PDFViewerViewModel {

    /// Persists the current page as this document's resume point.
    /// - Saves nothing until a load has identified the document, which stops a
    ///   failed or abandoned load from clearing a stored row, since saving
    ///   index `0` deletes it.
    func saveLastReadPage() async {
        guard let readyState,
              let documentIdentifierForLastViewedPageIndex =
                readyState.documentIdentifierForLastViewedPageIndex
        else { return }
        // Until the jump to the stored page has landed, the stored page is
        // still the resume point, and the document shows its top instead.
        guard readyState.initialPageIndex == nil || didApplyInitialPageNavigation else { return }
        await dependency.lastPageUseCase.saveLastPageIndex(
            pageIndexForLastViewed(),
            forDocumentIdentifier: documentIdentifierForLastViewedPageIndex
        )
    }

    func isScrolledToTopDidChange(_ isScrolledToTop: Bool) {
        self.isScrolledToTop = isScrolledToTop
    }

    func initialPageNavigationDidApply() {
        didApplyInitialPageNavigation = true
    }

    private func pageIndexForLastViewed() -> Int {
        if let initialPageIndex = readyState?.initialPageIndex, !didApplyInitialPageNavigation {
            return initialPageIndex
        }
        // - `currentPageIndex` is the page at the viewport centre, which a
        //   short first page does not reach even when the document is at its
        //   top.
        // - `isScrolledToTop` is only re-checked on scrolls and page changes,
        //   so an inset change can leave it stale. Scrolling to the top again
        //   corrects it, which is enough for a resume point.
        return isScrolledToTop ? 0 : currentPageIndex
    }
}
