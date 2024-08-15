import MEGAAssets
import UIKit

struct ChatAttachmenToolbarConfigurationStrategy: ToolbarConfigurationStrategy {
    func configure(toolbar: UIToolbar, in viewController: PhotosBrowserViewController) {
        // Placeholder
        let images: [UIImage] = [
            MEGAAssetsImageProvider.image(named: "thumbnailsThin"),
            MEGAAssetsImageProvider.image(named: "export")
        ].compactMap { $0 }
        
        let actions: [UIAction] = [
            UIAction { [weak viewController] _ in viewController?.didTapAllMedia() },
            UIAction {[weak viewController] _ in viewController?.didTapExport() }
        ]
        
        toolbar.configure(with: images, actions: actions)
    }
}
