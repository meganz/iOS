import UIKit
import MEGASwift

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
    
    @objc func makeFilterActiveBarButton() -> UIBarButtonItem {
        let image = UIImage(named: Asset.Images.ActionSheetIcons.filterActive.name)?.withRenderingMode(.alwaysOriginal)
        let filterBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(onFilter))
        filterBarButtonItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Colors.Photos.rightBarButtonForeground.color], for: .normal
        )
        return filterBarButtonItem
    }
    
    @objc func makeContextMenuBarButton() -> UIBarButtonItem {
        guard #available(iOS 14.0, *), let config = contextMenuConfiguration(), let menu = contextMenuManager?.contextMenu(with: config) else { return makeDefaultContextMenuButton() }
        let button = makeDefaultContextMenuButton()
        button.action = nil
        button.menu = menu
        return button
    }
    
    @objc private func makeDefaultContextMenuButton() -> UIBarButtonItem {
        UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image, style: .plain, target: self, action: #selector(presentActionSheet(sender:)))
    }
    
    @objc private func presentActionSheet(sender: Any) {
        guard let menuConfig = contextMenuConfiguration(),
              let actions = contextMenuManager?.actionSheetActions(with: menuConfig) else { return }
        presentActionSheet(actions: actions)
    }
    
    private func presentActionSheet(actions: [ContextActionSheetAction]) {
        let actionSheetVC = ActionSheetViewController(actions: actions,
                                                      headerTitle: nil,
                                                      dismissCompletion: nil,
                                                      sender: nil)
        
        present(actionSheetVC, animated: true)
    }
    
    @objc func setupNavigationBarButtons() {
        setupLeftNavigationBarButtons()
        setupRightNavigationBarButtons()
    }
    
    func setupLeftNavigationBarButtons() {
        if isEditing {
            if #available(iOS 14.0, *) {
                self.objcWrapper_parent.navigationItem.setLeftBarButton(selectAllBarButtonItem, animated: false)
            } else {
                self.navigationItem.setLeftBarButton(selectAllBarButtonItem, animated: false)
            }
        } else {
            if #available(iOS 14.0, *) {
                self.objcWrapper_parent.navigationItem.setLeftBarButton(self.myAvatarManager?.myAvatarBarButton, animated: false)
            } else {
                self.navigationItem.setLeftBarButton(self.myAvatarManager?.myAvatarBarButton, animated: false)
            }
        }
    }
    
    @objc func setupRightNavigationBarButtons() {
        if isEditing {
            if #available(iOS 14.0, *) {
                self.objcWrapper_parent.navigationItem.setRightBarButton(cancelBarButtonItem, animated: true)
            } else {
                self.navigationItem.setRightBarButton(cancelBarButtonItem, animated: true)
            }
        } else {
            if viewModel.isContextMenuOnCameraUploadFeatureFlagEnabled {
                if #available(iOS 14.0, *) {
                    var rightButtons = [UIBarButtonItem]()
                    if photoLibraryContentViewModel.selectedMode == .all {
                        rightButtons.append(makeContextMenuBarButton())
                    }
                    if viewModel.isFilterActive {
                        rightButtons.append(filterBarButtonItem)
                    }
                    if objcWrapper_parent.navigationItem.rightBarButtonItems !~ rightButtons {
                        objcWrapper_parent.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
                    }
                } else {
                    let contextMenuButton = [makeDefaultContextMenuButton()]
                    if navigationItem.rightBarButtonItems !~ contextMenuButton {
                        navigationItem.setRightBarButtonItems(contextMenuButton, animated: true)
                    }
                }
            }  else {
                if #available(iOS 14.0, *) {
                    self.objcWrapper_parent.navigationItem.setRightBarButton(editBarButtonItem, animated: true)
                } else {
                    self.navigationItem.setRightBarButton(editBarButtonItem, animated: true)
                }
            }
        }
    }
    
    @objc func makeCancelBarButton() -> UIBarButtonItem {
        UIBarButtonItem(title: Strings.Localizable.cancel, style: .done, target: self, action: #selector(toggleEditing))
    }
    
    @objc func makeEditBarButton() -> UIBarButtonItem {
        UIBarButtonItem(image: Asset.Images.NavigationBar.selectAll.image, style: .plain, target: self, action: #selector(toggleEditing))
    }
    
    
    @objc func toggleEditing() {
        setEditing(!isEditing, animated: true)
        setupNavigationBarButtons()
    }
    
    @objc private func onFilter() {
        photoLibraryContentViewModel.showFilter.toggle()
    }
}

// MARK: - DisplayMenuDelegate
extension PhotosViewController: DisplayMenuDelegate {
    func displayMenu(didSelect action: DisplayAction, needToRefreshMenu: Bool) {
        if action == .select {
            toggleEditing()
        } else if action == .filter {
            onFilter()
        }
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        guard sortType != viewModel.sortOrderType(forKey: .cameraUploadExplorerFeed) else { return }
        viewModel.cameraUploadExplorerSortOrderType = sortType
        Helper.save(sortType.megaSortOrderType, for: PhotosViewModel.SortingKeys.cameraUploadExplorerFeed.rawValue)
        setupNavigationBarButtons()
    }
    
    func showActionSheet(with actions: [ContextActionSheetAction]) {
        let actionSheetVC = ActionSheetViewController(actions: actions, headerTitle: nil, dismissCompletion: nil, sender: nil)
        present(actionSheetVC, animated: true)
    }
}
