import UIKit

extension PhotosViewController {
    private func contextMenuConfiguration() -> CMConfigEntity? {
        CMConfigEntity(menuType: .display,
                       sortType: SortOrderType.newest,
                       isSharedItems: true,
                       isCameraUploadExplorer: true)
    }
    
    @objc func configureContextMenuManager() {
        contextMenuManager = ContextMenuManager(
            displayMenuDelegate: self,
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository())
        )
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
    
    private func enableContextMenuOnCameraUploader() {
        if #available(iOS 14.0, *) {
            guard let menuConfig = contextMenuConfiguration() else { return }
            editBarButtonItem?.image = Asset.Images.NavigationBar.moreNavigationBar.image
            editBarButtonItem?.menu = contextMenuManager?.contextMenu(with: menuConfig)
            editBarButtonItem?.isEnabled = true
            
            objcWrapper_parent.navigationItem.rightBarButtonItem = self.editBarButtonItem
            objcWrapper_parent.navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Colors.Photos.rightBarButtonForeground.color], for: .normal
            )
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
        if FeatureFlag.shouldEnableContextMenuOnCameraUploadExplorer {
            enableContextMenuOnCameraUploader()
        } else {
            disableContextMenuOnCameraUploader()
        }
    }
    
    @objc func cancelEditing (sender:UIButton) {
        setEditing(!isEditing, animated: true)
        setRightNavigationBarButtons()
        
        if FeatureFlag.shouldEnableContextMenuOnCameraUploadExplorer {
            editBarButtonItem?.action = nil
        }
    }
    
    private func enableContextMenuOnCameraUploaderOnSelect() {
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
        if FeatureFlag.shouldEnableContextMenuOnCameraUploadExplorer {
            enableContextMenuOnCameraUploaderOnSelect()
        } else {
            disableContextMenuOnCameraUploaderOnSelect()
        }
    }
}

// MARK: - DisplayMenuDelegate
extension PhotosViewController: DisplayMenuDelegate {
    func displayMenu(didSelect action: DisplayAction, needToRefreshMenu: Bool) {
        if action == .select {
            onSelect()
        }
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        
    }
    
    func showActionSheet(with actions: [ContextActionSheetAction]) {
        let actionSheetVC = ActionSheetViewController(actions: actions, headerTitle: nil, dismissCompletion: nil, sender: nil)
        present(actionSheetVC, animated: true)
    }
}
