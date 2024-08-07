import UIKit

struct ChatAttachmenToolbarConfigurationStrategy: ToolbarConfigurationStrategy {
    func configure(toolbar: UIToolbar, with images: [UIImage], in viewController: PhotosBrowserViewController) {
        // Placeholder
        let actions: [UIAction] = [UIAction { [weak viewController] _ in viewController?.didTapAllMedia() },
                                   UIAction { [weak viewController] _ in viewController?.didTapSlideShow() },
                                   UIAction {[weak viewController] _ in viewController?.didTapExport() }
        ]
        
        toolbar.configure(with: images, actions: actions, target: viewController)
    }
}
