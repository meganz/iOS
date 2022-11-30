import UIKit
import MEGADomain
import MEGASwift

extension PhotosViewController {
    private func contextMenuConfiguration() -> CMConfigEntity? {
        return CMConfigEntity(
            menuType: .menu(type: .display),
            sortType: viewModel.sortOrderType(forKey: .cameraUploadExplorerFeed).megaSortOrderType.toSortOrderEntity(),
            isCameraUploadExplorer: true,
            isFilterEnabled: true,
            isEmptyState: viewModel.mediaNodesArray.isEmpty
        )
    }
    
    @objc func configureContextMenuManager() {
        contextMenuManager = ContextMenuManager(
            displayMenuDelegate: self,
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo)
        )
    }
    
    @objc func makeFilterActiveBarButton() -> UIBarButtonItem {
        UIBarButtonItem(image: Asset.Images.ActionSheetIcons.filterActive.image.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(onFilter))
    }
    
    @objc func makeContextMenuBarButton() -> UIBarButtonItem? {
        guard let config = contextMenuConfiguration(), let menu = contextMenuManager?.contextMenu(with: config) else { return nil }
        return UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image, menu: menu)
    }
    
    @objc func setupNavigationBarButtons() {
        setupLeftNavigationBarButtons()
        setupRightNavigationBarButtons()
    }
    
    func setupLeftNavigationBarButtons() {
        if isEditing {
            self.objcWrapper_parent.navigationItem.setLeftBarButton(selectAllBarButtonItem, animated: false)
        } else {
            self.objcWrapper_parent.navigationItem.setLeftBarButton(self.myAvatarManager?.myAvatarBarButton, animated: false)
        }
    }
    
    @objc func setupRightNavigationBarButtons() {
        if isEditing {
            self.objcWrapper_parent.navigationItem.setRightBarButtonItems([cancelBarButtonItem], animated: true)
        } else {
            var rightButtons = [UIBarButtonItem]()
            if photoLibraryContentViewModel.selectedMode == .all || viewModel.mediaNodesArray.isEmpty, let barButton = makeContextMenuBarButton() {
                rightButtons.append(barButton)
            }
            if viewModel.isFilterActive {
                rightButtons.append(filterBarButtonItem)
            }
            if objcWrapper_parent.navigationItem.rightBarButtonItems !~ rightButtons {
                objcWrapper_parent.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
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
    func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool) {
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
}
