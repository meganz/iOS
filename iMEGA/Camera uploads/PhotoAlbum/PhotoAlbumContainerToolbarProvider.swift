import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import UIKit

@MainActor
protocol PhotoAlbumContainerToolbarProvider {
    func showToolbar()
    func hideToolbar()
    func updateToolbarButtonEnabledState(isSelected: Bool)
    func updateRemoveLinksToolbarButtons(canRemoveLinks: Bool)
}

extension PhotoAlbumContainerViewController: PhotoAlbumContainerToolbarProvider {
    func showToolbar() {
        guard let tabBarController = tabBarController else { return }
        guard !tabBarController.view.subviews.contains(toolbar) else { return }
        if toolbar.items == nil {
            toolbar.items = [shareLinkBarButton, flexibleItem, deleteBarButton]
        }
        toolbar.alpha = 0.0
        tabBarController.view.addSubview(toolbar)
        
        if !isLiquidGlassEnabled() {
            toolbar.backgroundColor = TokenColors.Background.surface1
        }
        
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor),
            toolbar.bottomAnchor.constraint(equalTo: tabBarController.tabBar.safeAreaLayoutGuide.bottomAnchor),
            toolbar.leadingAnchor.constraint(equalTo: tabBarController.tabBar.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: tabBarController.tabBar.trailingAnchor)
        ])
        
        UIView.animate(withDuration: 0.3) {
            self.toolbar.alpha = 1.0
            self.updateMainTabbarAlpha(with: 0.0)
        }
    }
    
    func hideToolbar() {
        guard toolbar.superview != nil else { return }
        
        UIView.animate(withDuration: 0.3) {
            self.toolbar.alpha = 0.0
            self.updateMainTabbarAlpha(with: 1.0)
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
        
        if isSelected {
            deleteBarButton.tintColor = TokenColors.Icon.primary
            shareLinkBarButton.tintColor = TokenColors.Icon.primary
        }
    }
    
    func updateRemoveLinksToolbarButtons(canRemoveLinks: Bool) {
        if canRemoveLinks {
            toolbar.items = [shareLinkBarButton, flexibleItem, removeLinksBarButton, flexibleItem, deleteBarButton]
            AppearanceManager.forceToolbarUpdate(toolbar)
        } else {
            toolbar.items = [shareLinkBarButton, flexibleItem, deleteBarButton]
        }
    }
    
    // MARK: - Private
    
    private func updateMainTabbarAlpha(with value: CGFloat) {
        if isLiquidGlassEnabled() {
            tabBarController?.tabBar.alpha = value
        }
    }
    
    private func isLiquidGlassEnabled() -> Bool {
        if #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() {
            true
        } else {
            false
        }
    }
}
