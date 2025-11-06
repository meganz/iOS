import UIKit

@MainActor
protocol ToolbarConfigurationStrategy {
    func configure(toolbar: UIToolbar, in viewController: PhotosBrowserViewController)
}
