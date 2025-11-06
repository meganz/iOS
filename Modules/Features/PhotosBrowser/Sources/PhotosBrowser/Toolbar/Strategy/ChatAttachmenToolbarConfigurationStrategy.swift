import MEGAAssets
import UIKit

struct ChatAttachmenToolbarConfigurationStrategy: ToolbarConfigurationStrategy {
    func configure(toolbar: UIToolbar, in viewController: PhotosBrowserViewController) {
        // Placeholder
        let toolbarItems: [PhotosBrowserToolbarItem] = [
            PhotosBrowserToolbarItem(image: MEGAAssets.UIImage.image(named: "thumbnailsThin") ?? UIImage(),
                                     action: UIAction { [weak viewController] _ in viewController?.didTapAllMedia() }),
            PhotosBrowserToolbarItem(image: MEGAAssets.UIImage.image(named: "export") ?? UIImage(),
                                     action: UIAction { [weak viewController] _ in viewController?.didTapExport() })
        ]
        
        toolbar.configure(with: toolbarItems)
    }
}
