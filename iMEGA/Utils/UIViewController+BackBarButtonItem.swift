import MEGAUIKit
import UIKit

extension UIViewController {
    @objc
    func setMenuCapableBackButtonWith(menuTitle: String) {
        navigationItem.backBarButtonItem = BackBarButtonItem(menuTitle: menuTitle)
    }
    
    @objc
    func assignAsMEGANavigationDelegate(delegate: MEGANavigationControllerDelegate) {
        if let nc = navigationController as? MEGANavigationController {
            nc.navigationDelegate = delegate
        } else {
            MEGALogError("unexpected type of navigation controller \(String(describing: navigationController)) for vc:\(self)")
        }
    }
}
