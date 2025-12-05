import MEGADesignToken
import UIKit

@MainActor
protocol MediaToolbarProvider: AnyObject {
    var toolbar: UIToolbar { get }
    var tabBarController: UITabBarController? { get }

    func showToolbar(with config: MediaBottomToolbarConfig)
    func hideToolbar()
    func updateToolbar(with config: MediaBottomToolbarConfig)
}

// MARK: - Default Implementation

extension MediaToolbarProvider {

    func showToolbar(with config: MediaBottomToolbarConfig) {
        guard let tabBarController = tabBarController else { return }
        guard !tabBarController.view.subviews.contains(toolbar) else {
            // If toolbar already visible, just update it
            updateToolbar(with: config)
            return
        }

        // Configure toolbar
        toolbar.alpha = 0.0
        toolbar.backgroundColor = TokenColors.Background.surface1

        // Add to tabBarController's view to cover the tab bar
        tabBarController.view.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        // Constrain to cover tab bar
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor),
            toolbar.bottomAnchor.constraint(equalTo: tabBarController.tabBar.safeAreaLayoutGuide.bottomAnchor),
            toolbar.leadingAnchor.constraint(equalTo: tabBarController.tabBar.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: tabBarController.tabBar.trailingAnchor)
        ])

        updateToolbar(with: config)

        UIView.animate(withDuration: 0.3) {
            self.toolbar.alpha = 1.0
        }
    }

    func hideToolbar() {
        guard toolbar.superview != nil else { return }

        // Fade out animation
        UIView.animate(withDuration: 0.3) {
            self.toolbar.alpha = 0.0
        } completion: { _ in
            self.toolbar.removeFromSuperview()
        }
    }

    func updateToolbar(with config: MediaBottomToolbarConfig) {
        // This should be implemented by the conforming type
        // as it needs access to the toolbar items factory
    }
}

// MARK: - Flexible Space Helper

extension UIBarButtonItem {
    static var flexibleSpace: UIBarButtonItem {
        UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }
}
