import Combine
import PDFKit
import SwiftUI
import UIKit

/// A `PDFView` that
/// - Prevents zooming content to sizes smaller than its bounds (still allows
/// bounce) by setting `minScaleFactor` to `scaleFactorForSizeToFit`, including
/// when bounds change.
/// - If the document's size exactly fits bounds (which is the starting scale),
/// automatically adjusts current zoom scale when bounds change, .
final class AutoFittingPDFView: PDFView {
    private let autoFittingViewModel = AutoFittingPDFViewModel()

    private var subscriptions = Set<AnyCancellable>()

    override var document: PDFDocument? {
        get { super.document }
        set {
            guard super.document !== newValue else { return }
            super.document = newValue
            autoFittingViewModel.documentDidChange()
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
struct PDFDisplayerView: UIViewRepresentable {
    let document: PDFDocument
    let onLinkTapped: (URL) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onLinkTapped: onLinkTapped)
    }
    
    func makeUIView(context: Context) -> AutoFittingPDFView {
        let pdfView = AutoFittingPDFView()
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.delegate = context.coordinator
        return pdfView
    }

    func updateUIView(_ pdfView: AutoFittingPDFView, context: Context) {
        guard pdfView.document !== document else { return }
        pdfView.document = document
    }

    @MainActor
    final class Coordinator: NSObject, PDFViewDelegate {
        private let onLinkTapped: (URL) -> Void

        init(onLinkTapped: @escaping (URL) -> Void) {
            self.onLinkTapped = onLinkTapped
        }

        nonisolated func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
            Task { @MainActor [weak self] in
                self?.onLinkTapped(url)
            }
        }
    }
}
