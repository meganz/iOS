import UIKit

protocol ToolbarConfigurationStrategy {
    func configure(toolbar: UIToolbar, with images: [UIImage], in viewController: PhotosBrowserViewController)
}
