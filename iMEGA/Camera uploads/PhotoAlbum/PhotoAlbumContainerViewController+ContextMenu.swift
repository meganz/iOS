import Combine
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPreference
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
        }
    }
    
    @objc func toggleEditing(sender: UIBarButtonItem) {
        isEditing.toggle()
        viewModel.editMode = isEditing ? .active : .inactive
    }
    
    var cancelBarButton: UIBarButtonItem {
        let style = if #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() {
            UIBarButtonItem.Style.plain
        } else {
            UIBarButtonItem.Style.done
        }
        let cancelBarButton = UIBarButtonItem(title: Strings.Localizable.cancel, style: style, target: self, action: #selector(toggleEditing))
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
