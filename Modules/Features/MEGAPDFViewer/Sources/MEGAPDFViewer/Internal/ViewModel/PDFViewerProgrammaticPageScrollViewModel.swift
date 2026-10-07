import Combine
import CoreGraphics
import Foundation

@MainActor
final class PDFViewerProgrammaticPageScrollViewModel {
    struct PageNavigationState: Equatable {
        let pageIndex: Int
        let pageCount: Int
        let isZoomedIn: Bool
    }

    struct PageNavigationUpdate: Equatable {
        let pageIndex: Int
        let shouldZoomToFit: Bool
    }

    struct ScrollContentState: Equatable {
        let contentOffsetY: CGFloat
        /// The navigated page's vertical centre, in content coordinates.
        let pageMidY: CGFloat
        let adjustedContentInsetTop: CGFloat
        let adjustedContentInsetBottom: CGFloat
        let contentHeight: CGFloat
        let viewportHeight: CGFloat
    }

    @Published private(set) var pageNavigationUpdate: PageNavigationUpdate?
    @Published private(set) var scrollContentOffsetY: CGFloat?

    var pageNavigationState: PageNavigationState? {
        didSet {
            goToPage()
        }
    }

    var scrollContentState: ScrollContentState? {
        didSet {
            centerPageInViewportClampedToDocumentScrollLimits()
        }
    }

    private func goToPage() {
        guard let pageNavigationState else { return }
        guard (0..<pageNavigationState.pageCount).contains(
            pageNavigationState.pageIndex
        ) else { return }

        pageNavigationUpdate = PageNavigationUpdate(
            pageIndex: pageNavigationState.pageIndex,
            shouldZoomToFit: pageNavigationState.isZoomedIn
        )
    }

    private func centerPageInViewportClampedToDocumentScrollLimits() {
        guard let scrollContentState else { return }
        // - Centres on the point that
        //   `MEGAPDFView.currentPageIndexAtViewportCenter` reads the current
        //   page from, so the reported page is the one navigated to unless the
        //   offset is clamped.
        // - A page taller than the viewport is centred too, not top-aligned:
        //   whether the reader wants its top, middle or bottom is unknown, so
        //   the centre is as good a landing point as any.
        let centeredOffsetY = scrollContentState.pageMidY
            - scrollContentState.viewportHeight / 2
        let minimumOffsetY = -scrollContentState.adjustedContentInsetTop
        let maximumOffsetY = max(
            minimumOffsetY,
            scrollContentState.contentHeight
                - scrollContentState.viewportHeight
                + scrollContentState.adjustedContentInsetBottom
        )
        let offsetY = min(max(centeredOffsetY, minimumOffsetY), maximumOffsetY)
        scrollContentOffsetY = offsetY == scrollContentState.contentOffsetY ? nil : offsetY
    }
}
