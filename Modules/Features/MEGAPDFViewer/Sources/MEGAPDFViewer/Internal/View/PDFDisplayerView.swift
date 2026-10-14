import Combine
import PDFKit
import SwiftUI
import UIKit

@MainActor
protocol MEGAPDFViewPageObservationDelegate: AnyObject {
    func pdfView(_ pdfView: MEGAPDFView, currentPageDidChange index: Int)
    func pdfView(_ pdfView: MEGAPDFView, isScrolledToTopDidChange isScrolledToTop: Bool)
    func pdfViewDidApplyInitialPageNavigation(_ pdfView: MEGAPDFView)
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

    private var subscriptions = Set<AnyCancellable>()

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
        bindEvents()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(document: PDFDocument) {
        guard self.document == nil else { return }
        self.document = document
        autoFittingViewModel.documentDidChange()
        configurePagingObservation()
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
            zoomScaleForSizeToFit: scaleFactorForSizeToFit
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
                guard let self else { return }
                requestPageNavigation(to: pageIndex)
                pageObservationDelegate?.pdfViewDidApplyInitialPageNavigation(self)
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
        minScaleFactor = zoomStateUpdate.minZoomScale
        if let zoomScale = zoomStateUpdate.zoomScale {
            scaleFactor = zoomScale
        }

        if zoomStateUpdate.shouldScrollToTop, let contentScrollView {
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
    let document: PDFDocument
    @Binding var currentPage: Int
    @Binding var isProgrammaticallyScrollingToCurrentPage: Bool
    @Binding var searchRequest: PDFSearchRequest?
    let initialPageIndex: Int?
    let onLinkTapped: @MainActor (URL) -> Void
    let onTap: @MainActor () -> Void
    let onIsScrolledToTopChange: @MainActor (Bool) -> Void
    let onInitialPageNavigationApplied: @MainActor () -> Void
    var onSearchSessionDidBegin: @MainActor (UUID) -> Void = { _ in }
    var onSearchSessionDidEnd: @MainActor (UUID) -> Void = { _ in }
    var onSearchResultDidChange: @MainActor (UUID, UUID, Int) -> Void = { _, _, _ in }

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

        if searchRequest != nil {
            context.coordinator.sendSearchRequest(to: pdfView)
        }

        guard isProgrammaticallyScrollingToCurrentPage else { return }
        context.coordinator.navigate(pdfView, to: currentPage)
    }

    @MainActor
    final class Coordinator: NSObject,
                             PDFViewDelegate,
                             MEGAPDFViewPageObservationDelegate,
                             MEGAPDFViewDocumentTapDelegate,
                             MEGAPDFViewSearchObservationDelegate {
        var parent: PDFDisplayerView

        init(parent: PDFDisplayerView) {
            self.parent = parent
        }

        func pdfView(_ pdfView: MEGAPDFView, currentPageDidChange index: Int) {
            parent.currentPage = index
        }

        func pdfView(_ pdfView: MEGAPDFView, isScrolledToTopDidChange isScrolledToTop: Bool) {
            parent.onIsScrolledToTopChange(isScrolledToTop)
        }

        func pdfViewDidApplyInitialPageNavigation(_ pdfView: MEGAPDFView) {
            parent.onInitialPageNavigationApplied()
        }

        func pdfViewDidReceiveDocumentTap(_ pdfView: MEGAPDFView) {
            parent.onTap()
        }

        func navigate(_ pdfView: MEGAPDFView, to pageIndex: Int) {
            // - Defers to next @MainActor run loop, to avoid writing to this
            //   binding during `updateUIView:`
            // - The flag is cleared first, so the current page that
            //   `pdfView.pagingScrollObservationMonitor` reports after this
            //   navigation's scroll is not taken as another navigation.
            Task { @MainActor [weak self, weak pdfView] in
                self?.parent.isProgrammaticallyScrollingToCurrentPage = false
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
                guard let self, let request = parent.searchRequest else { return }
                switch request {
                case .present: pdfView?.presentSearch()
                case .dismiss: pdfView?.dismissSearch()
                }
                parent.searchRequest = nil
            }
        }

        func pdfView(_ pdfView: MEGAPDFView, searchSessionDidBegin sessionID: UUID) {
            parent.onSearchSessionDidBegin(sessionID)
        }

        func pdfView(_ pdfView: MEGAPDFView, searchSessionDidEnd sessionID: UUID) {
            parent.onSearchSessionDidEnd(sessionID)
        }

        func pdfView(_ pdfView: MEGAPDFView, searchResultDidChange sessionID: UUID, generationID: UUID, resultID: Int) {
            parent.onSearchResultDidChange(sessionID, generationID, resultID)
        }

        nonisolated func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
            Task { @MainActor [weak self] in
                self?.parent.onLinkTapped(url)
            }
        }
    }
}
