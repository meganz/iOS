import UIKit
import SwiftUI
import Combine
import MEGADomain

// MARK: - Context Menu
extension PhotoAlbumContainerViewController {
    func updateBarButtons() {
        if isEditing {
            navigationItem.setRightBarButton(cancelBarButton, animated: true)
            leftBarButton = navigationItem.leftBarButtonItem
            navigationItem.setLeftBarButton(nil, animated: true)
            showToolbar()
        } else {
            navigationItem.setRightBarButton(selectBarButton, animated: true)
            navigationItem.setLeftBarButton(leftBarButton, animated: true)
            hideToolbar()
        }
    }
    
    @objc func toggleEditing(sender: UIBarButtonItem) {
        isEditing = !isEditing
        viewModel.editMode = isEditing ? .active : .inactive
        updateBarButtons()
    }
    
    var selectBarButton: UIBarButtonItem {
        UIBarButtonItem(image: Asset.Images.NavigationBar.selectAll.image, style: .plain, target: self, action: #selector(toggleEditing))
    }
    
    var cancelBarButton: UIBarButtonItem {
        let cancelBarButton = UIBarButtonItem(title: Strings.Localizable.cancel, style: .done, target: self, action: #selector(toggleEditing))
        cancelBarButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Colors.MediaDiscovery.exitButtonTint.color], for: .normal)
        return cancelBarButton
    }
    
    func updateRightBarButton() {
        guard FeatureFlagProvider().isFeatureFlagEnabled(for: .albumContextMenu) && pageTabViewModel.selectedTab == .album else {
            navigationItem.setRightBarButton(nil, animated: false)
            return
        }
        
        navigationItem.setRightBarButton(viewModel.shouldShowSelectBarButton ? selectBarButton : nil, animated: false)
    }
}
