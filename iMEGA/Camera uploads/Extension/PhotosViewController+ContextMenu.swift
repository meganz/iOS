import UIKit

extension PhotosViewController {
    private func contextMenuConfiguration() -> CMConfigEntity? {
        if #available(iOS 14.0, *) {
            return CMConfigEntity(
                menuType: .display,
                sortType: viewModel.sortOrderType(forKey: .cameraUploadExplorerFeed),
                isCameraUploadExplorer: true,
                isFilterEnabled: viewModel.shouldShowFilterMenuOnCameraUpload,
                isEmptyState: viewModel.mediaNodesArray.isEmpty
            )
        } else {
            return CMConfigEntity(
                menuType: .display,
                sortType: viewModel.sortOrderType(forKey: .cameraUploadExplorerFeed),
                isCameraUploadExplorer: true,
                isFilterEnabled: false,
                isEmptyState: viewModel.mediaNodesArray.isEmpty
            )
        }
    }
    
    @objc func configureContextMenuManager() {
        contextMenuManager = ContextMenuManager(
            displayMenuDelegate: self,
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo)
        )
    }
    
    @objc private func presentActionSheet(sender: Any) {
        guard let menuConfig = contextMenuConfiguration(),
              let actions = contextMenuManager?.actionSheetActions(with: menuConfig) else { return }
        presentActionSheet(actions: actions)
    }
    
    @objc func updateRightNavigationBarButtons() {
        setEditing(false, animated: false)
        setRightNavigationBarButtons()
    }
    
    func updateMenuBarButtonItems(_ activeTabSelectionMode: PhotoLibraryViewMode) {
        if activeTabSelectionMode == .all {
            enableContextMenuOnCameraUploader()
        } else if activeTabSelectionMode != .all && viewModel.isFilterActive {
            objcWrapper_parent.navigationItem.rightBarButtonItem = filterActiveBarButtonItem
        } else {
            if #available(iOS 14.0, *) {
                self.objcWrapper_parent.navigationItem.rightBarButtonItems = nil;
            }
            else {
                self.navigationItem.rightBarButtonItem = nil;
            }
        }
    }
    
    private func presentActionSheet(actions: [ContextActionSheetAction]) {
        let actionSheetVC = ActionSheetViewController(actions: actions,
                                                      headerTitle: nil,
                                                      dismissCompletion: nil,
                                                      sender: nil)
        
        present(actionSheetVC, animated: true)
    }
    
    private var filterActiveBarButtonItem: UIBarButtonItem {
        let image = UIImage(named: Asset.Images.ActionSheetIcons.filterActive.name)?.withRenderingMode(.alwaysOriginal)
        return UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(onFilter))
    }
    
    private func enableContextMenuOnCameraUploader() {
        if #available(iOS 14.0, *) {
            guard let menuConfig = contextMenuConfiguration(), let editBarButtonItem = editBarButtonItem else { return }
            let newMenuItem = contextMenuManager?.contextMenu(with: menuConfig)
            if UIMenu.compareMenuItem(newMenuItem, editBarButtonItem.menu) == false {
                editBarButtonItem.image = Asset.Images.NavigationBar.moreNavigationBar.image
                editBarButtonItem.menu = newMenuItem
                editBarButtonItem.isEnabled = true
                editBarButtonItem.target = nil
                editBarButtonItem.action = nil
                
                var rightBarButtonItems = [editBarButtonItem]
                if viewModel.isFilterActive {
                    rightBarButtonItems.append(filterActiveBarButtonItem)
                }
                objcWrapper_parent.navigationItem.rightBarButtonItems = rightBarButtonItems
                editBarButtonItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Colors.Photos.rightBarButtonForeground.color], for: .normal
                )
            }
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image, style: .plain, target: self, action: #selector(presentActionSheet(sender:)))
        }
    }
    
    private func disableContextMenuOnCameraUploader() {
        if #available(iOS 14.0, *) {
            editBarButtonItem?.image = Asset.Images.NavigationBar.selectAll.image
            editBarButtonItem?.menu = nil
            editBarButtonItem?.isEnabled = true
            editBarButtonItem?.target = self
            editBarButtonItem?.action = #selector(onSelect)
            
            objcWrapper_parent.navigationItem.rightBarButtonItem = editBarButtonItem
            objcWrapper_parent.navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Colors.Photos.rightBarButtonForeground.color], for: .normal
            )
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.selectAll.image, style: .plain, target: self, action: #selector(onSelect))
        }
    }
    
    @objc func setRightNavigationBarButtons() {
        if viewModel.isContextMenuOnCameraUploadFeatureFlagEnabled {
            updateMenuBarButtonItems(photoLibraryContentViewModel.selectedMode)
        } else {
            disableContextMenuOnCameraUploader()
        }
    }
    
    @objc func cancelEditing() {
        setEditing(!isEditing, animated: true)
        setRightNavigationBarButtons()
        
        if viewModel.isContextMenuOnCameraUploadFeatureFlagEnabled  {
            editBarButtonItem?.action = nil
        }
    }
    
    private func enableContextMenuOnCameraUploaderOnSelect() {
        if #available(iOS 14.0, *) {
            guard let editBarButtonItem = editBarButtonItem else { return }
            setEditing(!isEditing, animated: true)
            editBarButtonItem.menu = nil
            editBarButtonItem.target = self
            editBarButtonItem.action = #selector(cancelEditing)
            
            objcWrapper_parent.navigationItem.rightBarButtonItems = nil
            objcWrapper_parent.navigationItem.rightBarButtonItem = editBarButtonItem
        } else {
            setEditing(!isEditing, animated: true)
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: Strings.Localizable.cancel,
                style: .plain,
                target: self,
                action: #selector(cancelEditing)
            )
            navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Colors.Photos.rightBarButtonForeground.color], for: .normal
            )
        }
    }
    
    private func disableContextMenuOnCameraUploaderOnSelect() {
        if #available(iOS 14.0, *) {
            setEditing(!isEditing, animated: true)
            editBarButtonItem?.menu = nil
            editBarButtonItem?.target = self
            editBarButtonItem?.action = #selector(cancelEditing)
        } else {
            setEditing(!isEditing, animated: true)
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: Strings.Localizable.cancel,
                style: .plain,
                target: self,
                action: #selector(cancelEditing)
            )
            navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Colors.Photos.rightBarButtonForeground.color], for: .normal
            )
        }
    }
    
    @objc private func onSelect() {
        if viewModel.isContextMenuOnCameraUploadFeatureFlagEnabled {
            enableContextMenuOnCameraUploaderOnSelect()
        } else {
            disableContextMenuOnCameraUploaderOnSelect()
        }
    }
    
    @objc private func onFilter() {
        photoLibraryContentViewModel.showFilter.toggle()
    }
}

// MARK: - DisplayMenuDelegate
extension PhotosViewController: DisplayMenuDelegate {
    func displayMenu(didSelect action: DisplayAction, needToRefreshMenu: Bool) {
        if action == .select {
            onSelect()
        } else if action == .filter {
            onFilter()
        }
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        guard sortType != viewModel.sortOrderType(forKey: .cameraUploadExplorerFeed) else { return }
        viewModel.cameraUploadExplorerSortOrderType = sortType
        Helper.save(sortType.megaSortOrderType, for: PhotosViewModel.SortingKeys.cameraUploadExplorerFeed.rawValue)
        setRightNavigationBarButtons()
    }
    
    func showActionSheet(with actions: [ContextActionSheetAction]) {
        let actionSheetVC = ActionSheetViewController(actions: actions, headerTitle: nil, dismissCompletion: nil, sender: nil)
        present(actionSheetVC, animated: true)
    }
}
