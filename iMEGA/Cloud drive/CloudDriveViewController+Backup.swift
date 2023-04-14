import MEGADomain

extension CloudDriveViewController {
    private func contextMenuBackupConfiguration() -> CMConfigEntity? {
        guard let parentNode else { return nil }
        
        let parentNodeAccessLevel = MEGASdkManager.sharedMEGASdk().accessLevel(for: parentNode)
        let isIncomingSharedRootChild = parentNodeAccessLevel != .accessOwner && MEGASdkManager.sharedMEGASdk().parentNode(for: parentNode) == nil
        let parentNodeEntity = parentNode.toNodeEntity()
        let backupsUseCase = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let isBackupsNode = backupsUseCase.isBackupsRootNode(parentNodeEntity)
        var isBackupsChild = false
        if !isBackupsNode {
            isBackupsChild = backupsUseCase.isBackupNode(parentNodeEntity)
        }
       
        return CMConfigEntity(menuType: .menu(type: .display),
                              viewMode: isListViewModeSelected() ? .list : .thumbnail,
                              accessLevel: parentNodeAccessLevel.toShareAccessLevelEntity(),
                              sortType: SortOrderType(megaSortOrderType: Helper.sortType(for: parentNode)).megaSortOrderType.toSortOrderEntity(),
                              isAFolder: parentNode.type != .root,
                              isRubbishBinFolder: displayMode == .rubbishBin,
                              isViewInFolder: isFromViewInFolder,
                              isIncomingShareChild: isIncomingSharedRootChild,
                              isBackupsRootNode: isBackupsNode,
                              isBackupsChild: isBackupsChild,
                              isOutShare: parentNode.isOutShare(),
                              isExported: parentNode.isExported(),
                              showMediaDiscovery: shouldShowMediaDiscovery())
    }
    
    @objc func setBackupNavigationBarButtons() {
        guard let menuConfig = contextMenuBackupConfiguration() else { return }
        contextBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image,
                                               menu: contextMenuManager?.contextMenu(with: menuConfig))
        
        if displayMode != .rubbishBin,
           displayMode != .backup,
           !isFromViewInFolder,
           let parentNode = parentNode,
           MEGASdkManager.sharedMEGASdk().accessLevel(for: parentNode) != .accessRead {
            guard let menuConfig = uploadAddMenuConfiguration() else { return }
            uploadAddBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.add.image,
                                                     menu: contextMenuManager?.contextMenu(with: menuConfig))
            navigationItem.rightBarButtonItems = [contextBarButtonItem, uploadAddBarButtonItem]
        } else {
            navigationItem.rightBarButtonItems = [contextBarButtonItem]
        }

        if presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.Localizable.close,
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(dismissController))
        }
    }
    
    @objc func showCustomActionsForBackupNode(_ node: MEGANode, sender: Any) {
        let backupsUseCase = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let isBackupNode = backupsUseCase.isBackupNode(node.toNodeEntity())
        showNodeActionsForNode(node, isIncoming: false, isBackupNode: isBackupNode, sender: sender)
    }
    
    @objc func toolbarActionsForNode(_ node: MEGANode) {
        guard let parentNode else { return }
        
        let backupsUseCase = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let isBackupNode = backupsUseCase.isBackupNode(node.toNodeEntity())
        let shareType: MEGAShareType = isBackupNode ? .accessRead : MEGASdkManager.sharedMEGASdk().accessLevel(for: parentNode)
        
        toolbarActions(for: shareType, isBackupNode: isBackupNode)
    }
}
