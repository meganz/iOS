@testable import MEGA
import XCTest

@MainActor
final class UIViewControllerAdditionsTests: XCTestCase {

    func testTopPresentableViewController_whenNothingIsPresented_shouldReturnSelf() {
        let window = UIWindow()
        let root = MockPresentingViewController()
        attach(root, to: window)

        XCTAssertIdentical(root.topPresentableViewController(), root)
    }

    func testTopPresentableViewController_whenWholeStackIsLive_shouldReturnDeepestController() {
        let window = UIWindow()
        let (root, _, top) = makeStack(in: window)

        XCTAssertIdentical(root.topPresentableViewController(), top)
    }

    func testTopPresentableViewController_whenTopIsBeingDismissed_shouldReturnNil() {
        let window = UIWindow()
        let (root, _, top) = makeStack(in: window)
        top.stubbedIsBeingDismissed = true

        // Its presenter still holds it, so UIKit would refuse a presentation there too.
        XCTAssertNil(root.topPresentableViewController())
    }

    func testTopPresentableViewController_whenTopIsOffWindow_shouldReturnNil() {
        let window = UIWindow()
        let (root, _, top) = makeStack(in: window)
        top.view.removeFromSuperview()

        XCTAssertNil(root.topPresentableViewController())
    }

    func testTopPresentableViewController_whenDismissedTopIsGone_shouldReturnItsPresenter() {
        let window = UIWindow()
        let (root, middle, _) = makeStack(in: window)
        middle.stubbedPresentedViewController = nil

        XCTAssertIdentical(root.topPresentableViewController(), middle)
    }

    func testTopPresentableViewController_whenNoControllerIsOnWindow_shouldReturnNil() {
        let root = MockPresentingViewController()

        XCTAssertNil(root.topPresentableViewController())
    }

    // MARK: - Helpers

    /// Builds root → middle → top, every one of them live on `window`.
    private func makeStack(
        in window: UIWindow
    ) -> (root: MockPresentingViewController, middle: MockPresentingViewController, top: MockPresentingViewController) {
        let root = MockPresentingViewController()
        let middle = MockPresentingViewController()
        let top = MockPresentingViewController()
        [root, middle, top].forEach { attach($0, to: window) }
        root.stubbedPresentedViewController = middle
        middle.stubbedPresentedViewController = top

        return (root, middle, top)
    }

    /// Loads the view and puts it on the window, which is what `isViewReady()` reads.
    private func attach(_ viewController: UIViewController, to window: UIWindow) {
        window.addSubview(viewController.view)
    }
}

private final class MockPresentingViewController: UIViewController {
    var stubbedPresentedViewController: UIViewController?
    var stubbedIsBeingDismissed = false

    override var presentedViewController: UIViewController? { stubbedPresentedViewController }
    override var isBeingDismissed: Bool { stubbedIsBeingDismissed }
}
