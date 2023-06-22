import Foundation
import MEGAData
import MEGADomain

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
    
    // MARK: - Context Menus configuration
    func contextMenuConfiguration() -> CMConfigEntity {
        return CMConfigEntity(menuType: .menu(type: .display),
                              sortType: SortOrderType(megaSortOrderType: sortOrderType).megaSortOrderType.toSortOrderEntity(),
                              isSharedItems: true)
    }
    
    @objc func setNavigationBarButtons() {
        if tableView?.isEditing ?? false {
            editBarButtonItem?.title = Strings.Localizable.cancel
            navigationItem.leftBarButtonItem = selectAllBarButtonItem
            navigationItem.rightBarButtonItem = editBarButtonItem
        } else {
            contextMenuManager = ContextMenuManager(displayMenuDelegate: self, createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo))
            
            contextBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image,
                                                   menu: contextMenuManager?.contextMenu(with: contextMenuConfiguration()))
            
            contextBarButtonItem.accessibilityLabel = Strings.Localizable.more
            
            navigationItem.rightBarButtonItem = contextBarButtonItem
            navigationItem.leftBarButtonItem = myAvatarManager?.myAvatarBarButton
        }
    }
    
    func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool) {
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
        setNavigationBarButtons()
    }

    // MARK: - NodeActionMenu
    @objc func showPendingOutShareModal(forIndexPath indexPath: IndexPath) {
        guard let share = shareAtIndexPath(indexPath), let userEmail = share.user else {
            return
        }
        viewModel.showPendingOutShareModal(for: userEmail)
    }
    
    @objc func showContactVerificationView(forIndexPath indexPath: IndexPath?) {
        guard let indexPath else { return }
        
        guard let userContact = userContactFromShareAtIndexPath(indexPath) else {
            showPendingOutShareModal(forIndexPath: indexPath)
            return
        }
        
        guard let verifyCredentialsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "VerifyCredentialsViewControllerID") as? VerifyCredentialsViewController else {
            return
        }
        
        verifyCredentialsVC.user = userContact
        verifyCredentialsVC.userName = userContact.mnz_displayName ?? userContact.email
        
        let isIncomingTab = incomingButton?.isSelected ?? false
        verifyCredentialsVC.setContactVerification(isIncomingTab)
        verifyCredentialsVC.statusUpdateCompletionBlock = { [weak self] in
            self?.reloadUI()
        }
        
        let navigationController = MEGANavigationController(rootViewController: verifyCredentialsVC)
        navigationController.addRightCancelButton()
        self.present(navigationController, animated: true)
    }
}
