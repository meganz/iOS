import MEGAAssets
import UIKit

struct CloudDriveToolbarConfigurationStrategy: ToolbarConfigurationStrategy {
    func configure(toolbar: UIToolbar, in viewController: PhotosBrowserViewController) {
        let toolbarItems: [PhotosBrowserToolbarItem] = [
            PhotosBrowserToolbarItem(image: MEGAAssetsImageProvider.image(named: "thumbnailsThin") ?? UIImage(),
                                     action: UIAction { [weak viewController] _ in viewController?.didTapAllMedia() }),
            PhotosBrowserToolbarItem(image: UIImage(systemName: "play.rectangle") ?? UIImage(),
                                     action: UIAction { [weak viewController] _ in viewController?.didTapSlideShow() }),
            PhotosBrowserToolbarItem(image: MEGAAssetsImageProvider.image(named: "export") ?? UIImage(),
                                     action: UIAction { [weak viewController] _ in viewController?.didTapExport() })
        ]
        
        toolbar.configure(with: toolbarItems)
    }
}
