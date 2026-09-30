import Combine
import PDFKit
import SwiftUI
import UIKit

@MainActor
protocol MEGAPDFViewPageObservationDelegate: AnyObject {
    func pdfView(_ pdfView: MEGAPDFView, currentPageDidChange index: Int)
}

final class MEGAPDFView: PDFView {
    private let autoFittingViewModel = AutoFittingPDFViewModel()
    private let pagingScrollObservationMonitor = PDFViewerPagingScrollObservationMonitor()

    private var subscriptions = Set<AnyCancellable>()

    weak var pageObservationDelegate: (any MEGAPDFViewPageObservationDelegate)?
    override var document: PDFDocument? {
        get { super.document }
        set {
            guard super.document !== newValue else { return }
            super.document = newValue
            autoFittingViewModel.documentDidChange()
            configurePagingObservation()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        bindEvents()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        autoFittingViewModel.zoomState = .init(
            zoomScale: scaleFactor,
            minZoomScale: minScaleFactor,
            zoomScaleForSizeToFit: scaleFactorForSizeToFit
        )
    }

    private func bindEvents() {
        autoFittingViewModel.$zoomStateUpdate
            .compactMap { $0 }
            .sink { [weak self] zoomStateUpdate in
                self?.apply(zoomStateUpdate)
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

    private var contentScrollView: UIScrollView? {
        subviews.compactMap { $0 as? UIScrollView }.first
    }
}

/// Renders an already-parsed `PDFDocument` inside SwiftUI.
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
    let onLinkTapped: @MainActor (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> MEGAPDFView {
        let pdfView = MEGAPDFView(frame: .zero)
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.delegate = context.coordinator
        pdfView.pageObservationDelegate = context.coordinator
        return pdfView
    }

    func updateUIView(_ pdfView: MEGAPDFView, context: Context) {
        context.coordinator.parent = self
        if pdfView.document !== document {
            pdfView.document = document
        }
        // The `currentPage` binding's forward direction will be addressed in an
        // upcoming MR.
    }

    @MainActor
    final class Coordinator: NSObject,
                             PDFViewDelegate,
                             MEGAPDFViewPageObservationDelegate {
        var parent: PDFDisplayerView

        init(parent: PDFDisplayerView) {
            self.parent = parent
        }

        func pdfView(_ pdfView: MEGAPDFView, currentPageDidChange index: Int) {
            parent.currentPage = index

        }

        nonisolated func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
            Task { @MainActor [weak self] in
                self?.parent.onLinkTapped(url)
            }
        }
    }
}
