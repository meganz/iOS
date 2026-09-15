import Foundation
import MEGAAppPresentation
import MEGAPDFViewer
/// Routes PDF nodes to the revamped SwiftUI viewer (`MEGAPDFViewer`) when the
/// `.pdfPreviewRevamp` feature flag is enabled. Legacy `PreviewDocumentViewController`
/// remains the fallback and keeps handling non-PDF documents.
@objc final class PDFViewerRevampRouter: NSObject {
    @objc static var isEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .pdfPreviewRevamp)
    }

    /// Viewer for a PDF that is already on disk (offline files / already-downloaded nodes).
    @objc @MainActor static func viewController(filePath: String, node: MEGANode?, isLink: Bool, isFromSharedItem: Bool) -> UIViewController {
        makeViewController(
            fileName: node?.name ?? filePath.lastPathComponent,
            pdfDocumentSource: .local(URL(fileURLWithPath: filePath))
        )
    }

    // MARK: - Private

    @MainActor
    private static func makeViewController(
        fileName: String,
        pdfDocumentSource: PDFViewerDocumentSource
    ) -> UIViewController {
        let dependency = PDFViewerView.Dependency(
            pdfDocumentSource: pdfDocumentSource,
            fileName: fileName,
            onLinkTapped: { url in
                MEGALinkManager.linkURL = url
                MEGALinkManager.processLinkURL(url)
            }
        )

        let viewer = PDFViewerViewController(dependency: dependency)
        viewer.modalPresentationStyle = .fullScreen
        return viewer
    }
}
