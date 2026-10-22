import PDFKit
@testable import MEGAPDFViewer
import Testing
import UIKit

private let viewport = CGSize(width: 393, height: 852)

struct PageFitTestDocument: CustomTestStringConvertible, Sendable {
    let pageSizes: [CGSize]
    var rotation = 0
    var widestPageIndex = 0

    var testDescription: String {
        pageSizes.map { "\($0.width)x\($0.height)" }.joined(separator: "+")
            + (rotation == 0 ? "" : " rotated \(rotation)")
    }
}

private let smallerThanDefaultMaxDocuments = [
    PageFitTestDocument(pageSizes: [CGSize(width: 3.84, height: 3.84)]),
    PageFitTestDocument(pageSizes: [CGSize(width: 50, height: 50)])
]

private let smallerThanViewportDocuments = smallerThanDefaultMaxDocuments + [
    PageFitTestDocument(pageSizes: [CGSize(width: 100, height: 100)]),
    PageFitTestDocument(pageSizes: [CGSize(width: 200, height: 200)]),
    PageFitTestDocument(pageSizes: [CGSize(width: 300, height: 400)]),
    PageFitTestDocument(pageSizes: [CGSize(width: 100, height: 100), CGSize(width: 200, height: 200)], widestPageIndex: 1),
    PageFitTestDocument(pageSizes: [CGSize(width: 50, height: 100)], rotation: 90)
]

private let largerThanViewportDocuments = [
    PageFitTestDocument(pageSizes: [CGSize(width: 612, height: 792)]),
    PageFitTestDocument(pageSizes: [CGSize(width: 842, height: 1191)]),
    PageFitTestDocument(pageSizes: [CGSize(width: 1191, height: 842)])
]

// Drives a real `MEGAPDFView` in a window: the fit, the zoom limits and the
// page geometry all come from PDFKit, which no mock can stand in for.
@MainActor
struct MEGAPDFViewSmallPageFitTests {
    // PDFKit's double tap zooms in only from `scaleFactorForSizeToFit`.
    @Test(arguments: smallerThanViewportDocuments)
    func pageRestsAtPDFKitFit(document: PageFitTestDocument) async throws {
        let (sut, window) = try await makeSUT(document: document)

        #expect(abs(sut.scaleFactor - sut.scaleFactorForSizeToFit) < 0.0001)
        #expect(sut.minScaleFactor <= sut.maxScaleFactor)
        withExtendedLifetime(window) {}
    }

    @Test(arguments: smallerThanDefaultMaxDocuments)
    func pageZoomsInPastFit(document: PageFitTestDocument) async throws {
        let (sut, window) = try await makeSUT(document: document)
        let fit = sut.scaleFactor

        sut.scaleFactor = fit * 2
        settleLayout(of: sut)

        #expect(fit > 5)
        #expect(abs(sut.scaleFactor - fit * 2) < 0.0001)
        withExtendedLifetime(window) {}
    }

    @Test(arguments: smallerThanViewportDocuments)
    func pageIsCentredWithGapsOfFourPointsPlusAtMostHalfAPageUnit(document: PageFitTestDocument) async throws {
        let (sut, window) = try await makeSUT(document: document)

        let pageFrame = try widestPageFrame(of: sut, document: document)
        let leftGap = pageFrame.minX
        let rightGap = sut.bounds.width - pageFrame.maxX
        #expect(abs(leftGap - rightGap) < 0.01)
        #expect(leftGap >= 4 - 0.01)
        #expect(leftGap <= 4 + sut.scaleFactor / 2 + 0.01)
        withExtendedLifetime(window) {}
    }

    @Test(arguments: largerThanViewportDocuments)
    func largePageKeepsPDFKitDefaultLayout(document: PageFitTestDocument) async throws {
        let (sut, window) = try await makeSUT(document: document)

        #expect(sut.pageBreakMargins == PDFView().pageBreakMargins)
        #expect(abs(sut.scaleFactor - sut.scaleFactorForSizeToFit) < 0.0001)
        withExtendedLifetime(window) {}
    }

    @Test
    func documentIsSetOnlyAfterDisplayPreparation() async throws {
        let frame = CGRect(origin: .zero, size: viewport)
        let window = UIWindow(frame: frame)
        let sut = MEGAPDFView(frame: frame)
        window.addSubview(sut)
        window.isHidden = false
        let data = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 3.84, height: 3.84)).pdfData { $0.beginPage() }
        let document = try #require(PDFDocument(data: data))
        let spy = DisplayPreparationSpy()
        sut.pageObservationDelegate = spy

        sut.configure(document: document)

        #expect(sut.document == nil)
        let deadline = ContinuousClock.now + .seconds(3)
        while spy.preparedCount == 0, ContinuousClock.now < deadline {
            sut.layoutIfNeeded()
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(spy.preparedCount == 1)
        #expect(sut.document === document)
        withExtendedLifetime(window) {}
    }

    private func widestPageFrame(of sut: MEGAPDFView, document: PageFitTestDocument) throws -> CGRect {
        let page = try #require(sut.document?.page(at: document.widestPageIndex))
        return sut.convert(page.bounds(for: sut.displayBox), from: page)
    }

    private func settleLayout(of sut: MEGAPDFView) {
        for _ in 0..<3 { sut.layoutIfNeeded() }
    }

    private func makeSUT(document: PageFitTestDocument) async throws -> (MEGAPDFView, UIWindow) {
        let frame = CGRect(origin: .zero, size: viewport)
        let window = UIWindow(frame: frame)
        let sut = MEGAPDFView(frame: frame)
        sut.displayMode = .singlePageContinuous
        sut.displayDirection = .vertical
        let data = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: document.pageSizes[0])).pdfData { context in
            for size in document.pageSizes {
                context.beginPage(withBounds: CGRect(origin: .zero, size: size), pageInfo: [:])
            }
        }
        let pdfDocument = try #require(PDFDocument(data: data))
        for index in 0..<pdfDocument.pageCount {
            pdfDocument.page(at: index)?.rotation = document.rotation
        }
        window.addSubview(sut)
        window.isHidden = false
        try await sut.configureAndAwaitDisplayPreparation(document: pdfDocument)
        return (sut, window)
    }
}
