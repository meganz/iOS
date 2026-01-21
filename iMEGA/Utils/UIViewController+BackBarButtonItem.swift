import MEGAAppPresentation
import MEGAUIKit
import UIKit

extension UIViewController {
    @objc
    func setMenuCapableBackButtonWith(menuTitle: String) {
        navigationItem.backBarButtonItem = BackBarButtonItem(menuTitle: menuTitle)
    }
    
    @objc func clearBackBarButton() {
        navigationItem.backBarButtonItem = nil
    }
    
    @objc
    func assignAsMEGANavigationDelegate(delegate: any MEGANavigationControllerDelegate) {
        if let nc = navigationController as? MEGANavigationController {
            nc.navigationDelegate = delegate
        } else {
            MEGALogError("unexpected type of navigation controller \(String(describing: navigationController)) for vc:\(self)")
        }
    }

    @objc func setupLiquidGlassNavigationBar() {
        setupLiquidGlassNavigationBar(with: .clear)
    }

    @objc func setupLiquidGlassNavigationBar(with backgroundColor: UIColor) {
        guard #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled(),
              let navBar = navigationController?.navigationBar else { return }
        AppearanceManager.setupLiquidGlassNavigationBar(navBar, backgroundColor: backgroundColor)
    }
}
