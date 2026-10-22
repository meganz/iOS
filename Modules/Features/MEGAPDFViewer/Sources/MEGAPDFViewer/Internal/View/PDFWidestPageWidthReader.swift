import CoreGraphics
import PDFKit

/// Reads the width `PDFView` fits to: the widest page in `displayBox`, with
/// pages rotated by 90 or 270 degrees measured by their height.
struct PDFWidestPageWidthReader {
    @concurrent nonisolated
    func widestPageWidth(of document: CGPDFDocument?, in displayBox: PDFDisplayBox) async -> CGFloat {
        guard let document, document.numberOfPages > 0 else { return 0 }
        let box = CGPDFBox(displayBox)
        var widestPageWidth: CGFloat = 0
        for pageNumber in 1...document.numberOfPages {
            guard !Task.isCancelled else { return 0 }
            guard let page = document.page(at: pageNumber) else { continue }
            let size = page.getBoxRect(box).size
            widestPageWidth = max(widestPageWidth, page.rotationAngle % 180 == 0 ? size.width : size.height)
        }
        return widestPageWidth
    }
}

private extension CGPDFBox {
    init(_ displayBox: PDFDisplayBox) {
        self = switch displayBox {
        case .mediaBox: .mediaBox
        case .cropBox: .cropBox
        case .bleedBox: .bleedBox
        case .trimBox: .trimBox
        case .artBox: .artBox
        @unknown default: .cropBox
        }
    }
}
