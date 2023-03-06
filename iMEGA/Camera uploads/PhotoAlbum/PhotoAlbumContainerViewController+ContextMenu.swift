import UIKit
import SwiftUI
import Combine
import MEGADomain

// MARK: - Context Menu
extension PhotoAlbumContainerViewController {
    @objc func toggleEditing(sender: UIBarButtonItem) {
        isEditing = !isEditing
        viewModel.editMode = isEditing ? .active : .inactive
        
        if isEditing {
            navigationItem.setRightBarButton(cancelBarButton, animated: true)
            leftBarButton = navigationItem.leftBarButtonItem
            navigationItem.setLeftBarButton(nil, animated: true)
        } else {
            navigationItem.setRightBarButton(selectBarButton, animated: true)
            navigationItem.setLeftBarButton(leftBarButton, animated: true)
        }
    }
    
    var selectBarButton: UIBarButtonItem {
        UIBarButtonItem(image: Asset.Images.NavigationBar.selectAll.image, style: .plain, target: self, action: #selector(toggleEditing))
    }
    
    var cancelBarButton: UIBarButtonItem {
        UIBarButtonItem(title: Strings.Localizable.cancel, style: .done, target: self, action: #selector(toggleEditing))
    }
    
    func updateRightBarButton() {
        guard FeatureFlagProvider().isFeatureFlagEnabled(for: .albumContextMenu) && pageTabViewModel.selectedTab == .album else {
            navigationItem.setRightBarButton(nil, animated: false)
            return
        }
        
        navigationItem.setRightBarButton(viewModel.shouldShowSelectBarButton ? selectBarButton : nil, animated: false)
    }
}
