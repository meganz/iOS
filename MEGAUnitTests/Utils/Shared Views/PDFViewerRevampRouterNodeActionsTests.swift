@testable import MEGA
import MEGAAppSDKRepoMock
import XCTest

@MainActor
final class PDFViewerRevampRouterNodeActionsTests: XCTestCase {
    private var windows: [UIWindow] = []

    func testNodeActionsSender_withBarItem_returnsBarItemOnIOS26() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("The bar item is used only on iOS 26 and later")
        }
        let barItem = UIBarButtonItem()

        let sender = PDFViewerRevampRouter.nodeActionsSender(
            anchor: makeAttachedAnchor(),
            barItem: barItem
        )

        XCTAssertIdentical(sender as AnyObject, barItem)
    }

    func testNodeActionsSender_withAttachedAnchor_returnsAnchor() {
        let anchor = makeAttachedAnchor()

        let sender = PDFViewerRevampRouter.nodeActionsSender(
            anchor: anchor,
            barItem: nil
        )

        XCTAssertIdentical(sender as AnyObject, anchor)
    }

    func testNodeActionsSender_withDetachedAnchor_returnsNil() {
        let sender = PDFViewerRevampRouter.nodeActionsSender(
            anchor: UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44)),
            barItem: nil
        )

        XCTAssertNil(sender)
    }

    func testNodeActionsSender_withZeroSizeAnchor_returnsNil() {
        let anchor = makeAttachedAnchor(size: .zero)

        let sender = PDFViewerRevampRouter.nodeActionsSender(
            anchor: anchor,
            barItem: nil
        )

        XCTAssertNil(sender)
    }

    func testNodeActionsSender_withoutAnchorOrBarItem_returnsNil() {
        let sender = PDFViewerRevampRouter.nodeActionsSender(
            anchor: nil,
            barItem: nil
        )

        XCTAssertNil(sender)
    }

    func testPresentNodeActions_withoutPresenter_callsOnPresentedOnce() {
        var onPresentedCallCount = 0

        PDFViewerRevampRouter.presentNodeActions(
            for: MockNode(handle: 1),
            from: nil,
            anchor: nil,
            barItem: nil,
            context: DocumentPreviewContext(
                isLink: false, fileLink: nil, isFromSharedItem: false
            ),
            onPresented: { onPresentedCallCount += 1 }
        )

        XCTAssertEqual(onPresentedCallCount, 1)
    }

    func testPresentNodeActions_whilePresenterIsPresenting_callsOnPresentedWithoutPresenting() {
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
            onPresented: { onPresentedCallCount += 1 }
        )

        XCTAssertEqual(onPresentedCallCount, 1)
        XCTAssertEqual(presenter.presentCallCount, 0)
    }

    private func makeAttachedAnchor(size: CGSize = CGSize(width: 44, height: 44)) -> UIView {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let anchor = UIView(frame: CGRect(origin: .zero, size: size))
        window.addSubview(anchor)
        windows.append(window)
        return anchor
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
}
