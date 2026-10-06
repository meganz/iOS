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
            clampScrollContentOffset()
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

    private func clampScrollContentOffset() {
        guard let scrollContentState else { return }
        let minimumOffsetY = -scrollContentState.adjustedContentInsetTop
        if scrollContentState.contentOffsetY < minimumOffsetY {
            scrollContentOffsetY = minimumOffsetY
            return
        }

        let maximumOffsetY = max(
            minimumOffsetY,
            scrollContentState.contentHeight
                - scrollContentState.viewportHeight
                + scrollContentState.adjustedContentInsetBottom
        )
        if scrollContentState.contentOffsetY > maximumOffsetY {
            scrollContentOffsetY = maximumOffsetY
            return
        }

        scrollContentOffsetY = nil
    }
}
