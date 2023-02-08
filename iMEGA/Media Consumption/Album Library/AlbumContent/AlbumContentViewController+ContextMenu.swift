import UIKit
import SwiftUI
import MEGAUIKit
import MEGADomain

extension AlbumContentViewController {
    private func contextMenuConfiguration(_ filterEnabled: Bool = true) -> CMConfigEntity? {
        return CMConfigEntity(
            menuType: .menu(type: .display),
            sortType: .modificationDesc,
            filterType: .allMedia,
            isAlbum: true,
            isFilterEnabled: filterEnabled
        )
    }
    
    func contextMenuManagerConfiguration() -> ContextMenuManager {
        ContextMenuManager(
            displayMenuDelegate: self,
            filterMenuDelegate: self,
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo)
        )
    }

    private func makeContextMenuBarButton(filterEnabled: Bool = true) -> UIBarButtonItem? {
        guard  let config = contextMenuConfiguration(filterEnabled),
               let menu = contextMenuManager?.contextMenu(with: config) else { return nil }
        return UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image, menu: menu)
    }
    
    func configureRightBarButton() {
        if isEditing {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .cancel,
                target: self,
                action: #selector(cancelButtonPressed(_:))
            )
            navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Colors.MediaDiscovery.exitButtonTint.color], for: .normal)
        } else {
            if FeatureFlagProvider().isFeatureFlagEnabled(for: .albumContextMenu) {
                navigationItem.rightBarButtonItem = makeContextMenuBarButton(filterEnabled: viewModel.isFilterEnabled)
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
    
    func sortMenu(didSelect sortType: SortOrderType) { }
}

// MARK: - FilterMenuDelegate
extension AlbumContentViewController: FilterMenuDelegate {
    func filterMenu(didSelect filterType: FilterType) { }
}

