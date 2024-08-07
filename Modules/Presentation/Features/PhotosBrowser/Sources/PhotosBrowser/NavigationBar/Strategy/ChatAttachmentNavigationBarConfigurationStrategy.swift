import MEGASwiftUI
import UIKit

struct ChatAttachmentNavigationBarConfigurationStrategy: NavigationBarConfigurationStrategy {
    func configure(navigationItem: UINavigationItem, in viewController: PhotosBrowserViewController) {
        // Placeholder
        let closeButton = UIBarButtonItem(title: "Close", primaryAction: UIAction { [weak viewController] _ in viewController?.didTapClose() })
        navigationItem.leftBarButtonItem = closeButton
        
        let titleView = NavigationTitleView(title: "Chat", subtitle: "Sub Title").toUIView()
        navigationItem.titleView = titleView
        navigationItem.titleView?.sizeToFit()
        
        let rightButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"),
                                          primaryAction: UIAction { [weak viewController] _ in viewController?.didTapAllMedia() })
        navigationItem.rightBarButtonItem = rightButton
    }
}
