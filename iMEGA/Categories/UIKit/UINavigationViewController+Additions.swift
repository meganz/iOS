import UIKit

extension UINavigationController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        if viewControllers.first?.isKind(of: LTHPasscodeViewController.self) ?? false {
            return .lightContent
        }

        return super.preferredStatusBarStyle
    }

    func setTitleStyle(_ textStyle: TextStyle) {
        let textAttributes = textStyle.applied(on: [:])
        navigationBar.titleTextAttributes = textAttributes
    }
}
