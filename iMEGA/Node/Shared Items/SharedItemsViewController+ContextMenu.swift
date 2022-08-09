import Foundation
extension SharedItemsViewController: DisplayMenuDelegate {
    @objc func tableView(_ tableView: UITableView,
                         contextMenuConfigurationForRowAt indexPath: IndexPath,
                         node: MEGANode) -> UIContextMenuConfiguration? {
        let contextMenuConfiguration = UIContextMenuConfiguration(identifier: nil) {
            if node.isFolder() {
                let cloudDriveVC = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "CloudDriveID") as? CloudDriveViewController
                cloudDriveVC?.parentNode = node
                cloudDriveVC?.displayMode = .cloudDrive
                return cloudDriveVC
            } else {
                return nil
            }
        } actionProvider: { _ in
            let selectAction = UIAction(title: Strings.Localizable.select,
                                        image: Asset.Images.ActionSheetIcons.select.image) { _ in
                self.didTapSelect()
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
            }
            return UIMenu(title: "", children: [selectAction])
        }

        return contextMenuConfiguration
    }
    
    @objc func willPerformPreviewActionForMenuWith(animator: UIContextMenuInteractionCommitAnimating) {
        guard let cloudDriveVC = animator.previewViewController as? CloudDriveViewController else { return }
        animator.addCompletion {
            self.navigationController?.pushViewController(cloudDriveVC, animated: true)
        }
    }
    
    //MARK: - Context Menus configuration
    func contextMenuConfiguration() -> CMConfigEntity {
        return CMConfigEntity(menuType: .display,
                              sortType: SortOrderType(megaSortOrderType: sortOrderType),
                              isSharedItems: true)
    }
    
    @objc func setNavigationBarButtons() {
        if tableView?.isEditing ?? false {
            editBarButtonItem?.title = Strings.Localizable.cancel
            navigationItem.leftBarButtonItem = selectAllBarButtonItem
            navigationItem.rightBarButtonItem = editBarButtonItem
        } else {
            contextMenuManager = ContextMenuManager(displayMenuDelegate: self, createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo))
            
            if #available(iOS 14.0, *) {
                contextBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image,
                                                       menu: contextMenuManager?.contextMenu(with: contextMenuConfiguration()))
            } else {
                contextBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image, style: .plain, target: self, action: #selector(presentActionSheet(sender:)))
            }
            
            contextBarButtonItem.accessibilityLabel = Strings.Localizable.more
            
            navigationItem.rightBarButtonItem = contextBarButtonItem
            navigationItem.leftBarButtonItem = myAvatarManager?.myAvatarBarButton
        }
    }
    
    @objc private func presentActionSheet(sender: Any) {
        guard let actions = contextMenuManager?.actionSheetActions(with: contextMenuConfiguration()) else { return }
        presentActionSheet(actions: actions)
    }
    
    //MARK: - DisplayMenuDelegate functions
    @objc func presentActionSheet(actions: [ContextActionSheetAction]) {
        let actionSheetVC = ActionSheetViewController(actions: actions,
                                                      headerTitle: nil,
                                                      dismissCompletion: nil,
                                                      sender: nil)

        self.present(actionSheetVC, animated: true)
    }
    
    func displayMenu(didSelect action: DisplayAction, needToRefreshMenu: Bool) {
        switch action {
        case .select:
            didTapSelect()
        default: break
        }
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        sortOrderType = sortType.megaSortOrderType
        UserDefaults.standard.set(sortOrderType.rawValue, forKey: "SharedItemsSortOrderType")
        nodesSortTypeHasChanged()
        if #available(iOS 14, *) {
            setNavigationBarButtons()
        }
    }
    
    func showActionSheet(with actions: [ContextActionSheetAction]) {
        let actionSheetVC = ActionSheetViewController(actions: actions, headerTitle: nil, dismissCompletion: nil, sender: nil)
        present(actionSheetVC, animated: true)
    }
}
