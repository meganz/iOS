@testable import MEGAPDFViewer
import PDFKit
import Testing
import UIKit

/// A `MEGAPDFView` in a window showing text pages, one string per page.
@MainActor
struct SearchFixture {
    let window: UIWindow
    let pdfView: MEGAPDFView
    let searcher: PDFDocumentSearcher

    init(pages: [String]) async throws {
        let frame = CGRect(x: 0, y: 0, width: 400, height: 700)
        window = UIWindow(frame: frame)
        let root = UIViewController()
        window.rootViewController = root
        window.makeKeyAndVisible()
        pdfView = MEGAPDFView(frame: frame)
        root.view.addSubview(pdfView)
        let bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 28)]
        let data = UIGraphicsPDFRenderer(bounds: bounds).pdfData { context in
            for page in pages {
                context.beginPage()
                page.draw(at: CGPoint(x: 48, y: 48), withAttributes: attributes)
            }
        }
        try await pdfView.configureAndAwaitDisplayPreparation(document: try #require(PDFDocument(data: data)))
        searcher = PDFDocumentSearcher(pdfView: pdfView)
    }
}
