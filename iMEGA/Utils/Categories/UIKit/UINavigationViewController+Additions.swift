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
    
    func popViewController(animated: Bool, completion: @escaping () -> Void) {
        popViewController(animated: animated)

        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion()
            }
        } else {
            completion()
        }
    }
}
