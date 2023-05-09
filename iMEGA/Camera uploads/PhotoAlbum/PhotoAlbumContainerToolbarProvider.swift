import UIKit
import MEGADomain

protocol PhotoAlbumContainerToolbarProvider {
    var isToolbarShown: Bool { get }
    
    func showToolbar()
    func hideToolbar()
    func updateToolbarButtonEnabledState(isSelected: Bool)
    func updateRemoveLinksToolbarButtons(canRemoveLinks: Bool)
}

extension PhotoAlbumContainerViewController: PhotoAlbumContainerToolbarProvider {
    var isToolbarShown: Bool {
        return toolbar.superview != nil
    }
    
    func showToolbar() {
        guard let tabBarController = tabBarController else { return }
        guard !tabBarController.view.subviews.contains(toolbar) else { return }
        if toolbar.items == nil {
            if isAlbumShareLinkEnabled {
                toolbar.items = [shareLinkBarButton, flexibleItem, deleteBarButton]
            } else {
                toolbar.items = [flexibleItem, deleteBarButton]
            }
        }
        toolbar.alpha = 0.0
        tabBarController.view.addSubview(toolbar)
        
        toolbar.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
        
        toolbar.autoPinEdge(.top, to: .top, of: tabBarController.tabBar)
        let bottomAnchor = tabBarController.tabBar.safeAreaLayoutGuide.bottomAnchor
        toolbar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        toolbar.autoPinEdge(.leading, to: .leading, of: tabBarController.tabBar)
        toolbar.autoPinEdge(.trailing, to: .trailing, of: tabBarController.tabBar)
        
        UIView.animate(withDuration: 0.3) {
            self.toolbar.alpha = 1.0
        }
    }
    
    func hideToolbar() {
        guard toolbar.superview != nil else { return }
        UIView.animate(withDuration: 0.3) {
            self.toolbar.alpha = 0.0
        } completion: { _ in
            self.toolbar.removeFromSuperview()
        }
    }
    
    var flexibleItem: UIBarButtonItem {
        UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                        target: nil,
                        action: nil)
    }
    
    func updateToolbarButtonEnabledState(isSelected: Bool) {
        deleteBarButton.isEnabled = isSelected
        shareLinkBarButton.isEnabled = isSelected
    }
    
    func updateRemoveLinksToolbarButtons(canRemoveLinks: Bool) {
        if canRemoveLinks {
            toolbar.items = [shareLinkBarButton, flexibleItem, removeLinksBarButton, flexibleItem, deleteBarButton]
        } else {
            toolbar.items = [shareLinkBarButton, flexibleItem, deleteBarButton]
        }
    }
}
