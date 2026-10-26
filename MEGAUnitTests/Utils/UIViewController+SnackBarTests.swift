@testable import MEGA
import SwiftUI
import Testing

@MainActor
struct UIViewControllerSnackBarTests {
    private static let overlayItemHeight: CGFloat = 60

    /// The mini player has a fixed height. The PSA banner has no fixed height and is sized by its content.
    enum OverlayItem: CaseIterable {
        case fixedHeight
        case contentHeight
    }

    @Test("A snack bar on a hosting screen in the tab bar shows above the bottom overlay", arguments: OverlayItem.allCases)
    func snackBarOnHostingScreenShowsAboveBottomOverlay(item: OverlayItem) throws {
        let (window, tabBarController, screen) = makeTabBarWithHostingScreen(overlayItem: item)

        screen.showSnackBar(message: "Message")
        window.layoutIfNeeded()

        let overlay = try #require(tabBarController.bottomOverlayContainer)
        let snackBarView = try #require(presentedSnackBarView(in: screen))
        #expect(overlay.frame.height == Self.overlayItemHeight)
        #expect(snackBarView.convert(snackBarView.bounds, to: window).maxY <= overlay.convert(overlay.bounds, to: window).minY)
    }

    @Test("Without overlay items a snack bar sits on the host's safe area bottom")
    func snackBarWithoutOverlayItemsSitsOnSafeAreaBottom() throws {
        let (window, _, screen) = makeTabBarWithHostingScreen(overlayItem: nil)

        screen.showSnackBar(message: "Message")
        window.layoutIfNeeded()

        let host = try #require(screen.navigationController?.view)
        let snackBarView = try #require(presentedSnackBarView(in: screen))
        let safeAreaBottom = host.convert(host.safeAreaLayoutGuide.layoutFrame, to: window).maxY
        #expect(snackBarView.convert(snackBarView.bounds, to: window).maxY == safeAreaBottom)
    }

    // MARK: - Helpers

    private func makeTabBarWithHostingScreen(overlayItem: OverlayItem?) -> (UIWindow, MainTabBarController, UIViewController) {
        let screen = UIHostingController(rootView: Color.clear)
        let tabBarController = TestMainTabBarController()
        tabBarController.viewControllers = [UINavigationController(rootViewController: screen)]

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = tabBarController
        window.isHidden = false
        window.layoutIfNeeded()

        switch overlayItem {
        case .fixedHeight:
            tabBarController.addSubviewToOverlay(UIView(), type: .audioPlayer, priority: .high, height: Self.overlayItemHeight)
        case .contentHeight:
            tabBarController.addSubviewToOverlay(ContentHeightView(height: Self.overlayItemHeight), type: .psa, priority: .normal)
        case nil:
            break
        }
        window.layoutIfNeeded()
        return (window, tabBarController, screen)
    }

    /// The snack bar is a child of the screen's navigation controller, added after the screen.
    private func presentedSnackBarView(in screen: UIViewController) -> UIView? {
        screen.navigationController?.children.last { $0 !== screen }?.view
    }
}

/// Builds only the bottom overlay. The real `viewDidLoad` loads every tab and registers SDK delegates.
private final class TestMainTabBarController: MainTabBarController {
    override func viewDidLoad() {
        setupBottomOverlayIfNeeded()
    }
}

/// Like the PSA banner: its height comes only from its content.
private final class ContentHeightView: UIView {
    private let height: CGFloat

    init(height: CGFloat) {
        self.height = height
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
}
