import PDFKit
import SwiftUI
import UIKit

/// Renders an already-parsed `PDFDocument` inside SwiftUI.
struct PDFDisplayerView: UIViewRepresentable {
    let document: PDFDocument
    let onLinkTapped: (URL) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onLinkTapped: onLinkTapped)
    }
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.delegate = context.coordinator
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
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
