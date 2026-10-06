import Combine
import PDFKit
import SwiftUI
import UIKit

@MainActor
protocol MEGAPDFViewPageObservationDelegate: AnyObject {
    func pdfView(_ pdfView: MEGAPDFView, currentPageDidChange index: Int)
}

@MainActor
protocol MEGAPDFViewDocumentTapDelegate: AnyObject {
    func pdfViewDidReceiveDocumentTap(_ pdfView: MEGAPDFView)
}

final class MEGAPDFView: PDFView {
    private let autoFittingViewModel = AutoFittingPDFViewModel()
    private let programmaticPageScrollViewModel = PDFViewerProgrammaticPageScrollViewModel()
    private let pagingScrollObservationMonitor = PDFViewerPagingScrollObservationMonitor()
    private let singleTapHandler = PDFDocumentSingleTapHandler()

    private var subscriptions = Set<AnyCancellable>()

    weak var pageObservationDelegate: (any MEGAPDFViewPageObservationDelegate)?
    weak var documentTapDelegate: (any MEGAPDFViewDocumentTapDelegate)?

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
        autoFittingViewModel.zoomState = .init(
            zoomScale: scaleFactor,
            minZoomScale: minScaleFactor,
            zoomScaleForSizeToFit: scaleFactorForSizeToFit
        )
    }

    func requestPageNavigation(to pageIndex: Int) {
        // - Aligns the given page's top with the viewport's top, without
        //   leaving extra space on the bottom or top.
        // - The current page, as reported by the
        //   `pagingScrollObservationMonitor`, is whatever page is at viewport
        //   center. This can be a different value than `pageIndex` if the
        //   page's height is short, such that the page does not reach the
        //   viewport center after alignment.
        // - We accept this for now - instead of forcing the current page index
        //   to the index targeted by `go(to:)`, we will show the page index at
        //   the viewport center, consistent with the page number updated when
        //   the user starts scrolling the page.
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

        pagingScrollObservationMonitor.dataSource = self
        pagingScrollObservationMonitor.onCurrentPageChange = { [weak self] currentPageIndex in
            guard let self else { return }
            pageObservationDelegate?.pdfView(
                self,
                currentPageDidChange: currentPageIndex
            )
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
        programmaticPageScrollViewModel.scrollContentState = .init(
            contentOffsetY: contentScrollView.contentOffset.y,
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

    private var contentScrollView: UIScrollView? {
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
}

struct PDFDisplayerView: UIViewRepresentable {
    let document: PDFDocument
    @Binding var currentPage: Int
    @Binding var isProgrammaticallyScrollingToCurrentPage: Bool
    let onLinkTapped: @MainActor (URL) -> Void
    let onTap: @MainActor () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> MEGAPDFView {
        let pdfView = MEGAPDFView(frame: .zero)
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.delegate = context.coordinator
        pdfView.documentTapDelegate = context.coordinator
        pdfView.pageObservationDelegate = context.coordinator
        pdfView.configure(document: document)
        return pdfView
    }

    func updateUIView(_ pdfView: MEGAPDFView, context: Context) {
        context.coordinator.parent = self

        guard isProgrammaticallyScrollingToCurrentPage else { return }
        context.coordinator.navigate(pdfView, to: currentPage)
    }

    @MainActor
    final class Coordinator: NSObject,
                             PDFViewDelegate,
                             MEGAPDFViewPageObservationDelegate,
                             MEGAPDFViewDocumentTapDelegate {
        var parent: PDFDisplayerView

        init(parent: PDFDisplayerView) {
            self.parent = parent
        }

        func pdfView(_ pdfView: MEGAPDFView, currentPageDidChange index: Int) {
            parent.currentPage = index
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

        nonisolated func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
            Task { @MainActor [weak self] in
                self?.parent.onLinkTapped(url)
            }
        }
    }
}
