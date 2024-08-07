import UIKit

protocol NavigationBarConfigurationStrategy {
    func configure(navigationItem: UINavigationItem, in viewController: PhotosBrowserViewController)
}
