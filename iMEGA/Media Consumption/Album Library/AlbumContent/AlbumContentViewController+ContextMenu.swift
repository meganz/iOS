import UIKit
import SwiftUI
import MEGAUIKit
import MEGADomain

extension AlbumContentViewController {
    func contextMenuManagerConfiguration() -> ContextMenuManager {
        ContextMenuManager(
            displayMenuDelegate: self,
            quickActionsMenuDelegate: self,
            filterMenuDelegate: self,
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo),
            albumMenuDelegate: self
        )
    }

    private func makeContextMenuBarButton() -> UIBarButtonItem? {
        guard let contextMenuConfig = viewModel.contextMenuConfiguration,
              let menu = contextMenuManager?.contextMenu(with: contextMenuConfig) else { return nil }
        
        return UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image, menu: menu)
    }
    
    func configureRightBarButtons() {
        if isEditing {
            let cancelBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .cancel,
                target: self,
                action: #selector(cancelButtonPressed(_:))
            )
            cancelBarButtonItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Colors.MediaDiscovery.exitButtonTint.color], for: .normal)
            navigationItem.rightBarButtonItems = [cancelBarButtonItem]
        } else {
            if FeatureFlagProvider().isFeatureFlagEnabled(for: .albumContextMenu) {
                var rightBarButtonItems = [UIBarButtonItem]()
                if let contextMenuBarButton = makeContextMenuBarButton() {
                    rightBarButtonItems.append(contextMenuBarButton)
                }
                if viewModel.canAddPhotosToAlbum {
                    rightBarButtonItems.append(addToAlbumBarButtonItem)
                }
                navigationItem.rightBarButtonItems = rightBarButtonItems
            } else {
                navigationItem.rightBarButtonItem = rightBarButtonItem
            }
        }
    }
}

// MARK: - DisplayMenuDelegate
extension AlbumContentViewController: DisplayMenuDelegate {
    func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool) {
        if action == .select {
            startEditingMode()
        }
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        viewModel.dispatch(.changeSortOrder(sortType))
    }
}

// MARK: - FilterMenuDelegate
extension AlbumContentViewController: FilterMenuDelegate {
    func filterMenu(didSelect filterType: FilterType) {
        viewModel.dispatch(.changeFilter(filterType))
    }
}

// MARK: - QuickActionsMenuDelegate
extension AlbumContentViewController: QuickActionsMenuDelegate {
    func quickActionsMenu(didSelect action: QuickActionEntity, needToRefreshMenu: Bool) {
        if action == .rename {
            viewModel.updateAlertViewModel()
            present(UIAlertController(alert: viewModel.alertViewModel), animated: true)
        }
    }
}

// MARK: - AlbumMenuDelegate
extension AlbumContentViewController: AlbumMenuDelegate {
    func albumMenu(didSelect action: AlbumActionEntity) {
        if action == .selectAlbumCover {  }
    }
}
