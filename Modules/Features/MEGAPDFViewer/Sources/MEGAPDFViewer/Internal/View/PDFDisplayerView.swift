import Combine
import PDFKit
import SwiftUI
import UIKit

@MainActor
protocol MEGAPDFViewPageObservationDelegate: AnyObject {
    func pdfView(_ pdfView: MEGAPDFView, currentPageDidChange index: Int)
    func pdfView(_ pdfView: MEGAPDFView, isScrolledToTopDidChange isScrolledToTop: Bool)
    func pdfViewDidFinishPreparingForDisplayAndInteraction(_ pdfView: MEGAPDFView)
}

@MainActor
protocol MEGAPDFViewDocumentTapDelegate: AnyObject {
    func pdfViewDidReceiveDocumentTap(_ pdfView: MEGAPDFView)
}

@MainActor
protocol MEGAPDFViewSearchObservationDelegate: AnyObject {
    func pdfView(_ pdfView: MEGAPDFView, searchSessionDidBegin sessionID: UUID)
    func pdfView(_ pdfView: MEGAPDFView, searchSessionDidEnd sessionID: UUID)
    func pdfView(_ pdfView: MEGAPDFView, searchResultDidChange sessionID: UUID, generationID: UUID, resultID: Int)
}

final class MEGAPDFView: PDFView {
    private let autoFittingViewModel = AutoFittingPDFViewModel()
    private let programmaticPageScrollViewModel = PDFViewerProgrammaticPageScrollViewModel()
    private let initialPageIndexScrollingViewModel = PDFViewerInitialPageIndexScrollingViewModel()
    private let pagingScrollObservationMonitor = PDFViewerPagingScrollObservationMonitor()
    private let singleTapHandler = PDFDocumentSingleTapHandler()
    private let searchInteractionHandler = PDFViewSearchInteractionHandler()
    private let widestPageWidthReader = PDFWidestPageWidthReader()

    private var subscriptions = Set<AnyCancellable>()
    private var prepareThenDisplayTask: Task<Void, Never>?
    private var widestPageWidth: CGFloat = 0
    private var defaultPageBreakMargins = UIEdgeInsets.zero

    weak var pageObservationDelegate: (any MEGAPDFViewPageObservationDelegate)?
    weak var documentTapDelegate: (any MEGAPDFViewDocumentTapDelegate)?
    weak var searchObservationDelegate: (any MEGAPDFViewSearchObservationDelegate)?

    /// Applied once the initial fit has scrolled to the top, which would
    /// otherwise undo the jump.
    var initialPageIndex: Int? {
        get { initialPageIndexScrollingViewModel.initialPageIndex }
        set { initialPageIndexScrollingViewModel.initialPageIndex = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        defaultPageBreakMargins = pageBreakMargins
        bindEvents()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        prepareThenDisplayTask?.cancel()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let contentScrollView {
            initialPageIndexScrollingViewModel.contentInsetState = .init(
                scrollViewAdjustedContentInsetTop: contentScrollView.adjustedContentInset.top,
                pdfViewSafeAreaInsetTop: safeAreaInsets.top
            )
        }
        autoFittingViewModel.zoomState = .init(
            zoomScale: scaleFactor,
            minZoomScale: minScaleFactor,
            zoomScaleForSizeToFit: scaleFactorForSizeToFit,
            widestPageWidth: widestPageWidth,
            pageBreakMargin: pageBreakMargins.left
        )
    }

    func presentSearch() {
        searchInteractionHandler.presentSearch()
    }

    func dismissSearch() {
        searchInteractionHandler.dismissSearch()
    }

    func requestPageNavigation(to pageIndex: Int) {
        programmaticPageScrollViewModel.pageNavigationState = .init(
            pageIndex: pageIndex,
            pageCount: document?.pageCount ?? 0,
            isZoomedIn: scaleFactor != scaleFactorForSizeToFit
        )
    }

    private func bindEvents() {
        singleTapHandler.configure(
            on: self,
            target: self,
            action: #selector(didSingleTap)
        )

        autoFittingViewModel.$zoomStateUpdate
            .compactMap { $0 }
            .sink { [weak self] zoomStateUpdate in
                self?.apply(zoomStateUpdate)
            }
            .store(in: &subscriptions)

        programmaticPageScrollViewModel.$pageNavigationUpdate
            .compactMap { $0 }
            .sink { [weak self] pageNavigationUpdate in
                self?.apply(pageNavigationUpdate)
            }
            .store(in: &subscriptions)

        programmaticPageScrollViewModel.$scrollContentOffsetY
            .compactMap { $0 }
            .sink { [weak self] contentOffsetY in
                self?.applyScrollContentOffset(contentOffsetY: contentOffsetY)
            }
            .store(in: &subscriptions)

        initialPageIndexScrollingViewModel.startObservingScrollToTop(
            didTriggerInitialScrollToTop: autoFittingViewModel.$didTriggerInitialScrollToTop
        )

        initialPageIndexScrollingViewModel.$initialPageNavigationRequest
            .compactMap { $0 }
            .sink { [weak self] pageIndex in
                self?.requestPageNavigation(to: pageIndex)
            }
            .store(in: &subscriptions)

        initialPageIndexScrollingViewModel.$didSettleInitialScrollPosition
            .filter { $0 }
            .sink { [weak self] _ in
                guard let self else { return }
                pageObservationDelegate?.pdfViewDidFinishPreparingForDisplayAndInteraction(self)
            }
            .store(in: &subscriptions)

        pagingScrollObservationMonitor.dataSource = self
        pagingScrollObservationMonitor.onCurrentPageChange = { [weak self] currentPageIndex in
            guard let self else { return }
            pageObservationDelegate?.pdfView(
                self,
                currentPageDidChange: currentPageIndex
            )
        }
        pagingScrollObservationMonitor.onIsScrolledToTopChange = { [weak self] isScrolledToTop in
            guard let self else { return }
            pageObservationDelegate?.pdfView(
                self,
                isScrolledToTopDidChange: isScrolledToTop
            )
        }

        searchInteractionHandler.attachToPDFView(self)
        searchInteractionHandler.onSearchSessionDidBegin = { [weak self] sessionID in
            guard let self else { return }
            searchObservationDelegate?.pdfView(self, searchSessionDidBegin: sessionID)
        }
        searchInteractionHandler.onSearchSessionDidEnd = { [weak self] sessionID in
            guard let self else { return }
            searchObservationDelegate?.pdfView(self, searchSessionDidEnd: sessionID)
        }
        searchInteractionHandler.onSearchResultChanged = { [weak self] sessionID, generationID, resultID in
            guard let self else { return }
            searchObservationDelegate?.pdfView(self, searchResultDidChange: sessionID, generationID: generationID, resultID: resultID)
        }
    }

    private func configurePagingObservation() {
        let keyValueEventSource = contentScrollView.map {
            PDFViewerPagingScrollObservationMonitor.KeyValueEventSource(
                keyPath: \UIScrollView.contentOffset,
                keyPathObject: $0
            )
        }
        pagingScrollObservationMonitor.startListeningToPageUpdateEvents(
            notificationEventSource: .init(
                notificationNames: [.PDFViewPageChanged, .PDFViewVisiblePagesChanged],
                notificationObject: self
            ),
            keyValueEventSource: keyValueEventSource
        )
    }

    private func apply(_ zoomStateUpdate: AutoFittingPDFViewModel.ZoomStateUpdate) {
        if abs(zoomStateUpdate.pageBreakMargin - pageBreakMargins.left) >= 0.0001 {
            let margin = zoomStateUpdate.pageBreakMargin
            pageBreakMargins = margin == defaultPageBreakMargins.left
                ? defaultPageBreakMargins
                : UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
            // `scaleFactorForSizeToFit` reflects new margins only once the
            // document view is laid out again; a layout of this view is not
            // enough.
            layoutDocumentView()
        }

        if let zoomThenScroll = zoomStateUpdate.zoomThenScroll {
            // Before the minimum, so the range stays valid when the fit is
            // above the current maximum.
            maxScaleFactor = zoomThenScroll.maxZoomScale
            minScaleFactor = zoomThenScroll.minZoomScale
            if let zoomScale = zoomThenScroll.zoomScale {
                scaleFactor = zoomScale
            }
        }

        if zoomStateUpdate.zoomThenScroll?.shouldScrollToTop == true, let contentScrollView {
            let topOffset = CGPoint(x: 0, y: -contentScrollView.adjustedContentInset.top)
            contentScrollView.setContentOffset(topOffset, animated: false)
        }

        setNeedsLayout()
    }

    private func apply(
        _ pageNavigationUpdate: PDFViewerProgrammaticPageScrollViewModel.PageNavigationUpdate
    ) {
        guard let document,
              let page = document.page(at: pageNavigationUpdate.pageIndex) else { return }
        if pageNavigationUpdate.shouldZoomToFit {
            scaleFactor = scaleFactorForSizeToFit
        }
        go(to: page)

        guard let contentScrollView else { return }
        let pageFrame = contentScrollView.convert(
            convert(page.bounds(for: displayBox), from: page),
            from: self
        )
        programmaticPageScrollViewModel.scrollContentState = .init(
            contentOffsetY: contentScrollView.contentOffset.y,
            pageMidY: pageFrame.midY,
            adjustedContentInsetTop: contentScrollView.adjustedContentInset.top,
            adjustedContentInsetBottom: contentScrollView.adjustedContentInset.bottom,
            contentHeight: contentScrollView.contentSize.height,
            viewportHeight: contentScrollView.bounds.height
        )
    }

    private func applyScrollContentOffset(contentOffsetY: CGFloat) {
        guard let contentScrollView else { return }
        contentScrollView.setContentOffset(
            CGPoint(x: contentScrollView.contentOffset.x, y: contentOffsetY),
            animated: false
        )
    }
}

// MARK: - Pre-display preparation

extension MEGAPDFView {
    /// Sets `document` once its widest page is known, then reports
    /// `pdfViewDidFinishPreparingForDisplayAndInteraction` after the initial
    /// fit and the jump to `initialPageIndex`.
    func configure(document: PDFDocument) {
        guard self.document == nil, prepareThenDisplayTask == nil else { return }
        prepareThenDisplayTask = Task { [weak self] in
            try? await self?.prepareThenDisplay(document)
        }
    }

    private func prepareThenDisplay(_ document: PDFDocument) async throws {
        try await prepareForDisplay(document)
        display(document)
    }

    private func prepareForDisplay(_ document: PDFDocument) async throws {
        // - Reads `documentRef` off the main actor, since a scan of every page
        //   can take seconds on a malformed page count.
        // - Nothing else reads `document` meanwhile: no `PDFView` has it
        //   until `display(_:)` sets it.
        nonisolated(unsafe) let documentRef = document.documentRef
        let widestPageWidth = await widestPageWidthReader.widestPageWidth(of: documentRef, in: displayBox)
        try Task.checkCancellation()
        self.widestPageWidth = widestPageWidth
    }

    private func display(_ document: PDFDocument) {
        self.document = document
        autoFittingViewModel.documentDidChange()
        configurePagingObservation()
        // Trigger initial fit as `document` setter doesn't queue up another
        // layout pass.
        setNeedsLayout()
    }

    func cancelDisplayPreparation() {
        prepareThenDisplayTask?.cancel()
        prepareThenDisplayTask = nil
    }
}

extension PDFView {
    var contentScrollView: UIScrollView? {
        subviews.compactMap { $0 as? UIScrollView }.first
    }
}

// MARK: - Single-tap handling

extension MEGAPDFView {
    @objc private func didSingleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        guard !areaOfInterest(for: location).contains(.linkArea) else { return }

        if currentSelection != nil {
            clearSelection()
            return
        }

        documentTapDelegate?.pdfViewDidReceiveDocumentTap(self)
    }
}

extension MEGAPDFView: PDFViewerPagingScrollObservationMonitorDataSource {
    var currentPageIndexAtViewportCenter: Int? {
        guard let document else { return nil }
        let viewportCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        guard let page = page(for: viewportCenter, nearest: true) else { return nil }
        return document.index(for: page)
    }

    var estimatedCurrentPageIndex: Int? {
        guard let document, let currentPage else { return nil }
        return document.index(for: currentPage)
    }

    var isScrolledToTop: Bool {
        guard document != nil, let contentScrollView else { return false }
        return contentScrollView.contentOffset.y
            <= -contentScrollView.adjustedContentInset.top + 0.5
    }
}

struct PDFDisplayerView: UIViewRepresentable {
    /// The bindings and callbacks of a displayed document.
    struct Interaction {
        struct Scroll {
            let currentPage: Binding<Int>
            let isProgrammaticallyScrollingToCurrentPage: Binding<Bool>
            let onIsScrolledToTopChange: @MainActor (Bool) -> Void
        }

        struct Search {
            let request: Binding<PDFSearchRequest?>
            var onSessionDidBegin: @MainActor (UUID) -> Void = { _ in }
            var onSessionDidEnd: @MainActor (UUID) -> Void = { _ in }
            var onResultDidChange: @MainActor (UUID, UUID, Int) -> Void = { _, _, _ in }
        }

        struct Tap {
            let onDocumentTapped: @MainActor () -> Void
            let onLinkTapped: @MainActor (URL) -> Void
        }

        let scroll: Scroll
        let search: Search
        let tap: Tap
    }

    let document: PDFDocument
    let initialPageIndex: Int?
    let onDidFinishPreparingForDisplayAndInteraction: @MainActor () -> Void
    /// Takes effect once the displayer finishes preparing `document`; changes
    /// before then are ignored.
    let interaction: Interaction

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> MEGAPDFView {
        let pdfView = MEGAPDFView(frame: .zero)
        pdfView.initialPageIndex = initialPageIndex
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.isFindInteractionEnabled = false
        pdfView.delegate = context.coordinator
        pdfView.documentTapDelegate = context.coordinator
        pdfView.pageObservationDelegate = context.coordinator
        pdfView.searchObservationDelegate = context.coordinator
        pdfView.configure(document: document)
        return pdfView
    }

    func updateUIView(_ pdfView: MEGAPDFView, context: Context) {
        context.coordinator.parent = self
        guard context.coordinator.isPreparedForDisplayAndInteraction else { return }
        context.coordinator.applyInteraction(to: pdfView)
    }

    static func dismantleUIView(_ pdfView: MEGAPDFView, coordinator: Coordinator) {
        pdfView.cancelDisplayPreparation()
    }

    @MainActor
    final class Coordinator: NSObject,
                             PDFViewDelegate,
                             MEGAPDFViewPageObservationDelegate,
                             MEGAPDFViewDocumentTapDelegate,
                             MEGAPDFViewSearchObservationDelegate {
        var parent: PDFDisplayerView
        private(set) var isPreparedForDisplayAndInteraction = false

        init(parent: PDFDisplayerView) {
            self.parent = parent
        }

        func applyInteraction(to pdfView: MEGAPDFView) {
            if parent.interaction.search.request.wrappedValue != nil {
                sendSearchRequest(to: pdfView)
            }

            guard parent.interaction.scroll.isProgrammaticallyScrollingToCurrentPage.wrappedValue else { return }
            navigate(pdfView, to: parent.interaction.scroll.currentPage.wrappedValue)
        }

        func pdfView(_ pdfView: MEGAPDFView, currentPageDidChange index: Int) {
            guard isPreparedForDisplayAndInteraction else { return }
            parent.interaction.scroll.currentPage.wrappedValue = index
        }

        func pdfView(_ pdfView: MEGAPDFView, isScrolledToTopDidChange isScrolledToTop: Bool) {
            guard isPreparedForDisplayAndInteraction else { return }
            parent.interaction.scroll.onIsScrolledToTopChange(isScrolledToTop)
        }

        func pdfViewDidFinishPreparingForDisplayAndInteraction(_ pdfView: MEGAPDFView) {
            isPreparedForDisplayAndInteraction = true
            parent.onDidFinishPreparingForDisplayAndInteraction()
            // The page and top changes from the initial fit and jump were not
            // reported, and `interaction` may have changed meanwhile.
            parent.interaction.scroll.currentPage.wrappedValue = pdfView.currentPageIndexAtViewportCenter ?? 0
            parent.interaction.scroll.onIsScrolledToTopChange(pdfView.isScrolledToTop)
            applyInteraction(to: pdfView)
        }

        func pdfViewDidReceiveDocumentTap(_ pdfView: MEGAPDFView) {
            guard isPreparedForDisplayAndInteraction else { return }
            parent.interaction.tap.onDocumentTapped()
        }

        func navigate(_ pdfView: MEGAPDFView, to pageIndex: Int) {
            // - Defers to next @MainActor run loop, to avoid writing to this
            //   binding during `updateUIView:`
            // - The flag is cleared first, so the current page that
            //   `pdfView.pagingScrollObservationMonitor` reports after this
            //   navigation's scroll is not taken as another navigation.
            Task { @MainActor [weak self, weak pdfView] in
                self?.parent.interaction.scroll.isProgrammaticallyScrollingToCurrentPage.wrappedValue = false
                pdfView?.requestPageNavigation(to: pageIndex)
            }
        }

        func sendSearchRequest(to pdfView: MEGAPDFView) {
            // - Defers to next @MainActor run loop, to avoid writing to this
            //   binding during `updateUIView:`
            // - Reads the request when the task runs and clears it after
            //   sending, so tasks queued by repeated `updateUIView:` calls send
            //   only the latest request, once.
            Task { @MainActor [weak self, weak pdfView] in
                guard let self, let request = parent.interaction.search.request.wrappedValue else { return }
                switch request {
                case .present: pdfView?.presentSearch()
                case .dismiss: pdfView?.dismissSearch()
                }
                parent.interaction.search.request.wrappedValue = nil
            }
        }

        func pdfView(_ pdfView: MEGAPDFView, searchSessionDidBegin sessionID: UUID) {
            guard isPreparedForDisplayAndInteraction else { return }
            parent.interaction.search.onSessionDidBegin(sessionID)
        }

        func pdfView(_ pdfView: MEGAPDFView, searchSessionDidEnd sessionID: UUID) {
            guard isPreparedForDisplayAndInteraction else { return }
            parent.interaction.search.onSessionDidEnd(sessionID)
        }

        func pdfView(_ pdfView: MEGAPDFView, searchResultDidChange sessionID: UUID, generationID: UUID, resultID: Int) {
            guard isPreparedForDisplayAndInteraction else { return }
            parent.interaction.search.onResultDidChange(sessionID, generationID, resultID)
        }

        nonisolated func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
            Task { @MainActor [weak self] in
                guard let self, isPreparedForDisplayAndInteraction else { return }
                parent.interaction.tap.onLinkTapped(url)
            }
        }
    }
}
