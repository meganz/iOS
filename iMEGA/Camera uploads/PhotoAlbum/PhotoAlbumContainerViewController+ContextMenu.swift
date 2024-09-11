import Combine
import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI
import UIKit

// MARK: - Context Menu
extension PhotoAlbumContainerViewController {
    func updateBarButtons() {
        guard pageTabViewModel.selectedTab == .album else { return }
        
        if isEditing {
            navigationItem.setRightBarButton(cancelBarButton, animated: true)
            navigationItem.setLeftBarButton(nil, animated: true)
        } else {
            navigationItem.setRightBarButton(selectBarButton, animated: false)
            navigationItem.setLeftBarButton(leftBarButton, animated: true)
        }
    }
    
    @objc func toggleEditing(sender: UIBarButtonItem) {
        isEditing.toggle()
        viewModel.editMode = isEditing ? .active : .inactive
    }
    
    var cancelBarButton: UIBarButtonItem {
        let cancelBarButton = UIBarButtonItem(title: Strings.Localizable.cancel, style: .done, target: self, action: #selector(toggleEditing))
        let normalForegroundColor = TokenColors.Text.primary
        cancelBarButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: normalForegroundColor], for: .normal)
        
        return cancelBarButton
    }
    
    func updateRightBarButton() {
        guard pageTabViewModel.selectedTab == .album else {
            navigationItem.setRightBarButtonItems(nil, animated: false)
            return
        }
        
        navigationItem.setRightBarButtonItems(viewModel.shouldShowSelectBarButton ? [selectBarButton] : nil, animated: false)
    }
}
