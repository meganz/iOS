import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import UIKit

struct ChatAttachmentNavigationBarConfigurationStrategy: NavigationBarConfigurationStrategy {
    
    func configure(navigationItem: UINavigationItem,
                   with library: MediaLibrary,
                   in viewController: PhotosBrowserViewController) {
        guard let asset = library.currentAsset else { return }
        
        // Placeholder
        let closeButton = UIBarButtonItem(title: Strings.Localizable.close,
                                          primaryAction: UIAction { [weak viewController] _ in viewController?.didTapClose() })
        closeButton.tintColor = TokenColors.Text.primary
        navigationItem.leftBarButtonItem = closeButton
        
        let formattedText = Strings.Localizable.Media.Photo.Browser.indexOfTotalFiles(library.assets.count)
        let subtitle = formattedText.replacingOccurrences(
            of: "[A]",
            with: String(format: "%lu", library.currentIndex + 1))
        let titleView = NavigationTitleView(title: asset.name, subtitle: subtitle).toUIView()
        navigationItem.titleView?.removeFromSuperview()
        navigationItem.titleView = titleView
        navigationItem.titleView?.sizeToFit()
        
        let rightButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"),
                                          primaryAction: UIAction { [weak viewController] _ in viewController?.didTapAllMedia() })
        rightButton.tintColor = TokenColors.Icon.primary
        navigationItem.rightBarButtonItem = rightButton
    }
}
