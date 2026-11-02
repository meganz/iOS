@testable import MEGAPDFViewer
import UIKit

extension UIView {
    /// The search overlay views PDFKit currently shows under this view.
    var searchHighlightOverlayViews: [PDFSearchHighlightOverlayView] {
        subviews.flatMap { subview -> [PDFSearchHighlightOverlayView] in
            (subview as? PDFSearchHighlightOverlayView).map { [$0] } ?? subview.searchHighlightOverlayViews
        }
    }
}
