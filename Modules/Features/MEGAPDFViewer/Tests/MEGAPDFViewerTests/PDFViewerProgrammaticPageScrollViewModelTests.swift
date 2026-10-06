import Foundation
@testable import MEGAPDFViewer
import Testing

@MainActor
struct PDFViewerProgrammaticPageScrollViewModelTests {
    @Test
    func newPageRequestWhileZoomedInRequestsFit() {
        let sut = PDFViewerProgrammaticPageScrollViewModel()

        sut.pageNavigationState = .init(
            pageIndex: 2,
            pageCount: 4,
            isZoomedIn: true
        )

        #expect(sut.pageNavigationUpdate == .init(pageIndex: 2, shouldZoomToFit: true))
    }

    @Test
    func newPageRequestWhileNotZoomedInDoesNotRequestFit() {
        let sut = PDFViewerProgrammaticPageScrollViewModel()

        sut.pageNavigationState = .init(
            pageIndex: 2,
            pageCount: 4,
            isZoomedIn: false
        )

        #expect(sut.pageNavigationUpdate == .init(pageIndex: 2, shouldZoomToFit: false))
    }

    @Test
    func invalidPageRequestDoesNotPublishNavigation() {
        let sut = PDFViewerProgrammaticPageScrollViewModel()

        sut.pageNavigationState = .init(
            pageIndex: 4,
            pageCount: 4,
            isZoomedIn: false
        )

        #expect(sut.pageNavigationUpdate == nil)
    }

    @Test(arguments: [
        (-30.0, -20.0),
        (500.0, 310.0)
    ] as [(CGFloat, CGFloat)])
    func outOfBoundsScrollContentOffsetPublishesBound(input: CGFloat, expected: CGFloat) {
        let sut = PDFViewerProgrammaticPageScrollViewModel()

        sut.scrollContentState = .init(
            contentOffsetY: input,
            adjustedContentInsetTop: 20,
            adjustedContentInsetBottom: 10,
            contentHeight: 700,
            viewportHeight: 400
        )

        #expect(sut.scrollContentOffsetY == expected)
    }

    @Test
    func inBoundsScrollContentOffsetDoesNotPublishCommand() {
        let sut = PDFViewerProgrammaticPageScrollViewModel()

        sut.scrollContentState = .init(
            contentOffsetY: 40,
            adjustedContentInsetTop: 20,
            adjustedContentInsetBottom: 10,
            contentHeight: 700,
            viewportHeight: 400
        )

        #expect(sut.scrollContentOffsetY == nil)
    }
}
