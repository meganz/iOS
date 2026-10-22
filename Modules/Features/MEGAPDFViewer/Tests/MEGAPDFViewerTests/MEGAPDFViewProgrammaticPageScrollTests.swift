import PDFKit
@testable import MEGAPDFViewer
import Testing
import UIKit

private let portraitViewport = CGSize(width: 390, height: 844)
private let landscapeViewport = CGSize(width: 844, height: 390)
/// Strip-shaped, far shorter than half the viewport at fit width.
private let shortPageSize = CGSize(width: 1600, height: 300)
/// A4, taller than the landscape viewport at fit width.
private let tallPageSize = CGSize(width: 595, height: 842)
private let pageCount = 40

// Drives a real `MEGAPDFView` in a window: the centring has to agree with
// PDFKit's own geometry, which no mock can stand in for. Assertions hold
// within the same turn of the run loop only.
@MainActor
struct MEGAPDFViewProgrammaticPageScrollTests {
    @Test
    func initialFitScrollsToDocumentTop() async throws {
        let (sut, window) = try await makeSUT(viewport: portraitViewport, pageSize: shortPageSize)

        #expect(sut.isScrolledToTop)
        #expect(abs(sut.scaleFactor - sut.scaleFactorForSizeToFit) < 0.0001)
        withExtendedLifetime(window) {}
    }

    @Test(arguments: [
        (portraitViewport, shortPageSize, 15),
        (landscapeViewport, tallPageSize, 5)
    ])
    func initialPageIsCenteredAfterInitialFit(viewport: CGSize, pageSize: CGSize, pageIndex: Int) async throws {
        let (sut, window) = try await makeSUT(viewport: viewport, pageSize: pageSize, initialPageIndex: pageIndex)

        try expectCentered(sut, pageIndex: pageIndex)
        withExtendedLifetime(window) {}
    }

    @Test(arguments: [
        (portraitViewport, shortPageSize, 15),
        (portraitViewport, shortPageSize, 30),
        (landscapeViewport, tallPageSize, 5)
    ])
    func navigatedPageIsCentered(viewport: CGSize, pageSize: CGSize, pageIndex: Int) async throws {
        let (sut, window) = try await makeSUT(viewport: viewport, pageSize: pageSize)

        sut.requestPageNavigation(to: pageIndex)
        sut.layoutIfNeeded()

        try expectCentered(sut, pageIndex: pageIndex)
        withExtendedLifetime(window) {}
    }

    @Test
    func navigatingToLastPageClampsToDocumentBottom() async throws {
        let (sut, window) = try await makeSUT(viewport: portraitViewport, pageSize: shortPageSize)

        sut.requestPageNavigation(to: pageCount - 1)
        sut.layoutIfNeeded()

        let scrollView = try contentScrollView(of: sut)
        let maximumOffsetY = scrollView.contentSize.height
            - scrollView.bounds.height
            + scrollView.adjustedContentInset.bottom
        #expect(abs(scrollView.contentOffset.y - maximumOffsetY) < 1)
        withExtendedLifetime(window) {}
    }

    @Test
    func navigatingBackToFirstPageReturnsToDocumentTop() async throws {
        let (sut, window) = try await makeSUT(viewport: portraitViewport, pageSize: shortPageSize)
        sut.requestPageNavigation(to: 15)
        sut.layoutIfNeeded()

        sut.requestPageNavigation(to: 0)
        sut.layoutIfNeeded()

        #expect(sut.isScrolledToTop)
        withExtendedLifetime(window) {}
    }

    /// Measured in `PDFView` coordinates, independently of the scroll view
    /// conversion that the centring itself uses.
    private func expectCentered(_ sut: MEGAPDFView, pageIndex: Int) throws {
        let page = try #require(sut.document?.page(at: pageIndex))
        let pageFrame = sut.convert(page.bounds(for: sut.displayBox), from: page)
        #expect(abs(pageFrame.midY - sut.bounds.midY) < 1)
        #expect(sut.currentPageIndexAtViewportCenter == pageIndex)
        #expect(!sut.isScrolledToTop)
    }

    private func contentScrollView(of sut: MEGAPDFView) throws -> UIScrollView {
        try #require(sut.subviews.compactMap { $0 as? UIScrollView }.first)
    }

    private func makeSUT(
        viewport: CGSize,
        pageSize: CGSize,
        initialPageIndex: Int? = nil
    ) async throws -> (MEGAPDFView, UIWindow) {
        let frame = CGRect(origin: .zero, size: viewport)
        let window = UIWindow(frame: frame)
        let sut = MEGAPDFView(frame: frame)
        sut.displayMode = .singlePageContinuous
        sut.displayDirection = .vertical
        sut.initialPageIndex = initialPageIndex
        let data = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize)).pdfData { context in
            for _ in 0..<pageCount { context.beginPage() }
        }
        window.addSubview(sut)
        window.isHidden = false
        try await sut.configureAndAwaitDisplayPreparation(document: try #require(PDFDocument(data: data)))
        return (sut, window)
    }
}
