import MEGAAssets
import UIKit

struct CloudDriveToolbarConfigurationStrategy: ToolbarConfigurationStrategy {
    func configure(toolbar: UIToolbar, in viewController: PhotosBrowserViewController) {
        let images: [UIImage] = [
            MEGAAssetsImageProvider.image(named: "thumbnailsThin"),
            UIImage(systemName: "play.rectangle"),
            MEGAAssetsImageProvider.image(named: "export")
        ].compactMap { $0 }
        
        let actions: [UIAction] = [
            UIAction { [weak viewController] _ in viewController?.didTapAllMedia() },
            UIAction { [weak viewController] _ in viewController?.didTapSlideShow() },
            UIAction {[weak viewController] _ in viewController?.didTapExport() }
        ]
        
        toolbar.configure(with: images, actions: actions)
    }
}
