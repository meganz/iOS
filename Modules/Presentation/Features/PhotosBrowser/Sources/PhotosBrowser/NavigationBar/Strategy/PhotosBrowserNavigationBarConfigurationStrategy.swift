import UIKit

protocol NavigationBarConfigurationStrategy {
    func configure(navigationItem: UINavigationItem,
                   with library: MediaLibrary,
                   in viewController: PhotosBrowserViewController)
}
