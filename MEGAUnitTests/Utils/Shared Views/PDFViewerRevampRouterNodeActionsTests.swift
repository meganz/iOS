@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGAPDFViewer
import Testing
import UIKit

@MainActor
struct PDFViewerRevampRouterNodeActionsTests {
    @Test func morePresentation_tracksOnlyAfterAcceptedPresentationCompletes() {
        let presenter = AcceptedPresentationSpy()
        let tracker = MockTracker()
        var animationRestorations = 0
        PDFViewerRevampRouter.presentNodeActions(
            for: MockNode(handle: 1), from: presenter, anchor: nil, barItem: nil,
            context: DocumentPreviewContext(isLink: false, fileLink: nil, isFromSharedItem: false),
            trackingUseCase: PDFViewerTrackingUseCase(tracker: tracker),
            analyticsSource: .node,
            onPresented: { animationRestorations += 1 }
        )

        #expect(tracker.trackedEventIdentifiers.isEmpty)
        #expect(animationRestorations == 0)
        presenter.completion?()
        #expect(tracker.trackedEventIdentifiers.count == 1)
        #expect(tracker.trackedEventIdentifiers.first is PdfViewerMoreMenuOpenedEvent)
        #expect(animationRestorations == 1)
    }

    @Test func rejectedMorePresentation_restoresAnimationWithoutTrackingOpen() {
        let tracker = MockTracker()
        var animationRestorations = 0
        PDFViewerRevampRouter.presentNodeActions(
            for: MockNode(handle: 1), from: PresentingSpy(), anchor: nil, barItem: nil,
            context: DocumentPreviewContext(isLink: false, fileLink: nil, isFromSharedItem: false),
            trackingUseCase: PDFViewerTrackingUseCase(tracker: tracker),
            analyticsSource: .node,
            onPresented: { animationRestorations += 1 }
        )

        #expect(tracker.trackedEventIdentifiers.isEmpty)
        #expect(animationRestorations == 1)
    }

    @Test(.enabled("The bar item is used only on iOS 26 and later") {
        if #available(iOS 26.0, *) { return true }
        return false
    })
    func nodeActionsSender_withBarItem_returnsBarItemOnIOS26() {
        let barItem = UIBarButtonItem()
        let (window, anchor) = makeAttachedAnchor()

        let sender = PDFViewerRevampRouter.nodeActionsSender(
            anchor: anchor,
            barItem: barItem
        )

        #expect(sender as AnyObject === barItem)
        withExtendedLifetime(window) {}
    }

    @Test func nodeActionsSender_withAttachedAnchor_returnsAnchor() {
        let (window, anchor) = makeAttachedAnchor()

        let sender = PDFViewerRevampRouter.nodeActionsSender(
            anchor: anchor,
            barItem: nil
        )

        #expect(sender as AnyObject === anchor)
        withExtendedLifetime(window) {}
    }

    @Test func nodeActionsSender_withDetachedAnchor_returnsNil() {
        let sender = PDFViewerRevampRouter.nodeActionsSender(
            anchor: UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44)),
            barItem: nil
        )

        #expect(sender == nil)
    }

    @Test func nodeActionsSender_withZeroSizeAnchor_returnsNil() {
        let (window, anchor) = makeAttachedAnchor(size: .zero)

        let sender = PDFViewerRevampRouter.nodeActionsSender(
            anchor: anchor,
            barItem: nil
        )

        #expect(sender == nil)
        withExtendedLifetime(window) {}
    }

    @Test func nodeActionsSender_withoutAnchorOrBarItem_returnsNil() {
        let sender = PDFViewerRevampRouter.nodeActionsSender(
            anchor: nil,
            barItem: nil
        )

        #expect(sender == nil)
    }

    @Test func presentNodeActions_withoutPresenter_callsOnPresentedOnce() {
        var onPresentedCallCount = 0

        PDFViewerRevampRouter.presentNodeActions(
            for: MockNode(handle: 1),
            from: nil,
            anchor: nil,
            barItem: nil,
            context: DocumentPreviewContext(
                isLink: false, fileLink: nil, isFromSharedItem: false
            ),
            analyticsSource: .node,
            onPresented: { onPresentedCallCount += 1 }
        )

        #expect(onPresentedCallCount == 1)
    }

    @Test func presentNodeActions_whilePresenterIsPresenting_callsOnPresentedWithoutPresenting() {
        let presenter = PresentingSpy()
        var onPresentedCallCount = 0

        PDFViewerRevampRouter.presentNodeActions(
            for: MockNode(handle: 1),
            from: presenter,
            anchor: nil,
            barItem: nil,
            context: DocumentPreviewContext(
                isLink: false, fileLink: nil, isFromSharedItem: false
            ),
            analyticsSource: .node,
            onPresented: { onPresentedCallCount += 1 }
        )

        #expect(onPresentedCallCount == 1)
        #expect(presenter.presentCallCount == 0)
    }

    private func makeAttachedAnchor(
        size: CGSize = CGSize(width: 44, height: 44)
    ) -> (window: UIWindow, anchor: UIView) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let anchor = UIView(frame: CGRect(origin: .zero, size: size))
        window.addSubview(anchor)
        return (window, anchor)
    }

    private final class PresentingSpy: UIViewController {
        private(set) var presentCallCount = 0

        override var presentedViewController: UIViewController? { UIViewController() }

        override func present(
            _ viewControllerToPresent: UIViewController,
            animated flag: Bool,
            completion: (() -> Void)? = nil
        ) {
            presentCallCount += 1
        }
    }

    private final class AcceptedPresentationSpy: UIViewController {
        var completion: (() -> Void)?

        override func present(
            _ viewControllerToPresent: UIViewController,
            animated flag: Bool,
            completion: (() -> Void)? = nil
        ) {
            self.completion = completion
        }
    }
}
