import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASDKRepo
import MEGASwift

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

    private func makeContextMenuBarButton(contextMenuConfiguration: CMConfigEntity?) -> UIBarButtonItem? {
        guard let contextMenuConfiguration,
              let menu = contextMenuManager?.contextMenu(with: contextMenuConfiguration) else { return nil }
        
        let button = UIBarButtonItem(image: UIImage.moreNavigationBar, menu: menu)
        button.tintColor = TokenColors.Text.primary
        return button
    }
    
    func configureRightBarButtons(contextMenuConfiguration: CMConfigEntity?, canAddPhotosToAlbum: Bool) {
        if isEditing {
            let cancelBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .cancel,
                target: self,
                action: #selector(cancelButtonPressed(_:))
            )
            
            cancelBarButtonItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: getBarButtonNormalForegroundColor()], for: .normal)
            navigationItem.rightBarButtonItems = [cancelBarButtonItem]
        } else {
            var rightBarButtonItems = [UIBarButtonItem]()
            if let contextMenuBarButton = makeContextMenuBarButton(contextMenuConfiguration: contextMenuConfiguration) {
                rightBarButtonItems.append(contextMenuBarButton)
            }
            if canAddPhotosToAlbum {
                rightBarButtonItems.append(addToAlbumBarButtonItem)
            }
            guard navigationItem.rightBarButtonItems !~ rightBarButtonItems else {
                return
            }
            
            for button in rightBarButtonItems {
                button.tintColor = TokenColors.Text.primary
            }
            
            navigationItem.rightBarButtonItems = rightBarButtonItems
        }
    }
    
    func getBarButtonNormalForegroundColor() -> UIColor {
        return TokenColors.Text.primary
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
            viewModel.dispatch(.renameAlbum)
        } else if action == .shareLink || action == .manageLink {
            viewModel.dispatch(.shareLink)
        } else if action == .removeLink {
            let alert = UIAlertController(title: Strings.Localizable.CameraUploads.Albums.removeShareLinkAlertTitle(1),
                                          message: Strings.Localizable.CameraUploads.Albums.removeShareLinkAlertMessage(1),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: { _ in
                alert.dismiss(animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: Strings.Localizable.CameraUploads.Albums.removeShareLinkAlertConfirmButtonTitle(1),
                                          style: .default, handler: { [weak self] _ in
                guard let self else { return }
                viewModel.dispatch(.removeLink)
            }))
            present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - AlbumMenuDelegate
extension AlbumContentViewController: AlbumMenuDelegate {
    func albumMenu(didSelect action: AlbumActionEntity) {
        if action == .selectAlbumCover {
            viewModel.dispatch(.showAlbumCoverPicker)
        } else if action == .delete {
            executeCommand(.showDeleteAlbumAlert)
        }
    }
}
