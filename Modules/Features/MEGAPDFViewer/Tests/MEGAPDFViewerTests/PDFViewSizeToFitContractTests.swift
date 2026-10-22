import PDFKit
import Testing
import UIKit

private let viewport = CGSize(width: 393, height: 852)

// Pins the `PDFView` behaviour `AutoFittingPDFViewModel` derives the centring
// margin from, on a plain `PDFView`, so a change in a future OS fails here by
// name rather than as an off-centre page elsewhere.
@MainActor
struct PDFViewSizeToFitContractTests {
    @Test(arguments: [
        (CGFloat(3.84), CGFloat(4)),
        (3.84, 0.08),
        (50, 4),
        (50, 0.5293),
        (100, 1.5),
        (612, 4),
        (595.28, 4)
    ])
    func fitIsWidthOverWidestPagePlusMarginsRoundedUp(pageWidth: CGFloat, margin: CGFloat) throws {
        let (sut, window) = try makeSUT(pageSizes: [CGSize(width: pageWidth, height: pageWidth)])

        setHorizontalPageBreakMargin(margin, of: sut)

        let roundedUpTotal = (pageWidth + 2 * margin - 0.000001).rounded(.up)
        #expect(abs(sut.scaleFactorForSizeToFit - viewport.width / roundedUpTotal) < 0.0001)
        withExtendedLifetime(window) {}
    }

    @Test
    func fitFollowsWidestPageAcrossAllPagesWithRotation() throws {
        let (sut, window) = try makeSUT(
            pageSizes: [CGSize(width: 200, height: 200), CGSize(width: 100, height: 300)],
            rotationOfLastPage: 90
        )

        #expect(abs(sut.scaleFactorForSizeToFit - viewport.width / (300 + 8)) < 0.0001)
        withExtendedLifetime(window) {}
    }

    @Test
    func newMarginsReachFitOnlyAfterDocumentViewLayout() throws {
        let (sut, window) = try makeSUT(pageSizes: [CGSize(width: 50, height: 50)])
        let fitWithDefaultMargins = sut.scaleFactorForSizeToFit

        sut.pageBreakMargins = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        sut.layoutIfNeeded()
        #expect(sut.scaleFactorForSizeToFit == fitWithDefaultMargins)

        sut.layoutDocumentView()
        #expect(abs(sut.scaleFactorForSizeToFit - viewport.width / 52) < 0.0001)
        withExtendedLifetime(window) {}
    }

    @Test
    func roundingRemainderIsLaidOutRightOfPage() throws {
        let (sut, window) = try makeSUT(pageSizes: [CGSize(width: 3.84, height: 3.84)])
        let margin: CGFloat = 0.04
        setHorizontalPageBreakMargin(margin, of: sut)
        sut.maxScaleFactor = sut.scaleFactorForSizeToFit
        sut.scaleFactor = sut.scaleFactorForSizeToFit
        sut.layoutIfNeeded()

        let page = try #require(sut.document?.page(at: 0))
        let pageFrame = sut.convert(page.bounds(for: sut.displayBox), from: page)
        let leftGap = pageFrame.minX
        let rightGap = sut.bounds.width - pageFrame.maxX
        #expect(abs(leftGap - margin * sut.scaleFactor) < 0.5)
        #expect(rightGap > leftGap + 1)
        withExtendedLifetime(window) {}
    }

    private func setHorizontalPageBreakMargin(_ margin: CGFloat, of sut: PDFView) {
        var margins = sut.pageBreakMargins
        margins.left = margin
        margins.right = margin
        sut.pageBreakMargins = margins
        sut.layoutDocumentView()
    }

    private func makeSUT(pageSizes: [CGSize], rotationOfLastPage: Int = 0) throws -> (PDFView, UIWindow) {
        let frame = CGRect(origin: .zero, size: viewport)
        let window = UIWindow(frame: frame)
        let sut = PDFView(frame: frame)
        sut.displayMode = .singlePageContinuous
        sut.displayDirection = .vertical
        let data = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSizes[0])).pdfData { context in
            for size in pageSizes {
                context.beginPage(withBounds: CGRect(origin: .zero, size: size), pageInfo: [:])
            }
        }
        let document = try #require(PDFDocument(data: data))
        document.page(at: document.pageCount - 1)?.rotation = rotationOfLastPage
        sut.document = document
        window.addSubview(sut)
        window.isHidden = false
        sut.layoutIfNeeded()
        return (sut, window)
    }
}
