import UIKit
import SwiftUI
import MEGAUIKit
import MEGADomain

extension AlbumContentViewController {
    private func contextMenuConfiguration() -> CMConfigEntity? {
        return CMConfigEntity(
            menuType: .menu(type: .display),
            sortType: SortOrderEntity.modificationDesc,
            isAlbum: true
        )
    }
    
    func contextMenuManagerConfiguration() -> ContextMenuManager {
        ContextMenuManager(
            displayMenuDelegate: self,
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo)
        )
    }

    private func makeContextMenuBarButton() -> UIBarButtonItem? {
        guard let config = contextMenuConfiguration(), let menu = contextMenuManager?.contextMenu(with: config) else { return nil }
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
        } else if viewModel.isUserAlbum {
            navigationItem.rightBarButtonItem = makeContextMenuBarButton()
        } else {
            navigationItem.rightBarButtonItem = rightBarButtonItem
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
