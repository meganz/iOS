@testable import MEGA
import MEGAAppPresentation
import Testing
import UIKit

@MainActor
struct BottomOverlayContainerHeightTests {
    @Test("An item that grows after it is added reports the new overlay height to the selected tab's last view controller")
    func growingItemReportsNewHeight() {
        let (window, tabBarController, screen) = makeTabBarWithPresenter()
        let item = ContentHeightView(height: 0)
        tabBarController.addSubviewToOverlay(item, type: .psa, priority: .normal)
        window.layoutIfNeeded()

        item.height = 175
        window.layoutIfNeeded()

        #expect(screen.reportedHeights.last == 175)
    }

    @Test("Adding and removing an item reports the overlay height to the selected tab's last view controller")
    func addingAndRemovingItemReportsHeight() {
        let (window, tabBarController, screen) = makeTabBarWithPresenter()

        tabBarController.addSubviewToOverlay(ContentHeightView(height: 4), type: .requestStatusProgress, priority: .highest)
        window.layoutIfNeeded()
        #expect(screen.reportedHeights.last == 4)

        tabBarController.removeSubviewFromOverlay(.requestStatusProgress)
        window.layoutIfNeeded()
        #expect(screen.reportedHeights.last == 0)
    }

    @Test("A layout update that changes the overlay height reports the new height once")
    func layoutUpdateReportsNewHeightOnce() {
        let (window, tabBarController, screen) = makeTabBarWithPresenter()

        tabBarController.updateOverlayLayout {
            tabBarController.addSubviewToOverlay(ContentHeightView(height: 60), type: .audioPlayer, priority: .high)
        }
        window.layoutIfNeeded()

        #expect(screen.reportedHeights == [60])
    }

    @Test("A layout update that keeps the overlay height still reports it to the selected tab's last view controller")
    func layoutUpdateWithSameHeightReportsHeight() {
        let (window, tabBarController, screen) = makeTabBarWithPresenter()
        tabBarController.addSubviewToOverlay(ContentHeightView(height: 60), type: .audioPlayer, priority: .high)
        window.layoutIfNeeded()

        tabBarController.updateOverlayLayout {}
        window.layoutIfNeeded()

        #expect(screen.reportedHeights == [60, 60])
    }

    // MARK: - Helpers

    private func makeTabBarWithPresenter() -> (UIWindow, MainTabBarController, PresenterScreen) {
        let screen = PresenterScreen()
        let tabBarController = TestMainTabBarController()
        tabBarController.viewControllers = [UINavigationController(rootViewController: screen)]

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = tabBarController
        window.isHidden = false
        window.layoutIfNeeded()
        return (window, tabBarController, screen)
    }
}

/// Builds only the bottom overlay. The real `viewDidLoad` loads every tab and registers SDK delegates.
private final class TestMainTabBarController: MainTabBarController {
    override func viewDidLoad() {
        setupBottomOverlayIfNeeded()
    }
}

private final class PresenterScreen: UIViewController {
    private(set) var reportedHeights: [CGFloat] = []
}

// MARK: - BottomOverlayPresenterProtocol
extension PresenterScreen: BottomOverlayPresenterProtocol {
    func updateContentView(_ height: CGFloat) {
        reportedHeights.append(height)
    }

    func hasUpdatedContentView() -> Bool {
        reportedHeights.last != 0
    }
}

/// Like the PSA banner: its height comes only from its content, which can change later.
private final class ContentHeightView: UIView {
    var height: CGFloat {
        didSet { invalidateIntrinsicContentSize() }
    }

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
