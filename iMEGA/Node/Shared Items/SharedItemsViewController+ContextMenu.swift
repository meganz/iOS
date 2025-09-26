import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAL10n

extension SharedItemsViewController: DisplayMenuDelegate {
    @objc func tableView(_ tableView: UITableView,
                         contextMenuConfigurationForRowAt indexPath: IndexPath,
                         node: MEGANode) -> UIContextMenuConfiguration? {
        let factory = CloudDriveViewControllerFactory.make(nc: navigationController)
        let contextMenuConfiguration = UIContextMenuConfiguration(identifier: nil) {
            if node.isFolder() {
                return factory.buildBare(parentNode: node.toNodeEntity())
            } else {
                return nil
            }
        } actionProvider: { _ in
            let selectAction = UIAction(title: Strings.Localizable.select,
                                        image: MEGAAssets.UIImage.selectItem) { _ in
                self.didTapSelect()
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
            }
            return UIMenu(title: "", children: [selectAction])
        }

        return contextMenuConfiguration
    }
    
    @objc func willPerformPreviewActionForMenuWith(animator: any UIContextMenuInteractionCommitAnimating) {
        guard let cloudDriveVC = animator.previewViewController  else { return }
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
            updateAvatarButtonItem()

            guard !DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .cloudDriveRevamp) else { return }

            contextMenuManager = ContextMenuManager(displayMenuDelegate: self, createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo))
            
            contextBarButtonItem = UIBarButtonItem(image: MEGAAssets.UIImage.moreNavigationBar,
                                                   menu: contextMenuManager?.contextMenu(with: contextMenuConfiguration()))
            
            contextBarButtonItem.accessibilityLabel = Strings.Localizable.more
            
            navigationItem.rightBarButtonItem = contextBarButtonItem
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

    @objc func updateAvatarButtonItem() {
        navigationItem.leftBarButtonItem = DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .navigationRevamp) ? nil : avatarBarButtonItem
    }
}
