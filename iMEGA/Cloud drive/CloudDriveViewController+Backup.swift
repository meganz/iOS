import MEGADomain

extension CloudDriveViewController {
    private func contextMenuBackupConfiguration() async -> CMConfigEntity? {
        guard let parentNode else { return nil }
        
        let parentNodeAccessLevel = MEGASdkManager.sharedMEGASdk().accessLevel(for: parentNode)
        let isIncomingSharedRootChild = parentNodeAccessLevel != .accessOwner && MEGASdkManager.sharedMEGASdk().parentNode(for: parentNode) == nil
        let parentNodeEntity = parentNode.toNodeEntity()
        let myBackupsUseCase = MyBackupsUseCase(myBackupsRepository: MyBackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let isMyBackupsNode = await myBackupsUseCase.isMyBackupsRootNode(parentNodeEntity)
        var isMyBackupsChild = false
        if !isMyBackupsNode {
            isMyBackupsChild = await myBackupsUseCase.isBackupNode(parentNodeEntity)
        }
       
        return CMConfigEntity(menuType: .menu(type: .display),
                              viewMode: isListViewModeSelected() ? .list : .thumbnail,
                              accessLevel: parentNodeAccessLevel.toShareAccessLevelEntity(),
                              sortType: SortOrderType(megaSortOrderType: Helper.sortType(for: parentNode)).megaSortOrderType.toSortOrderEntity(),
                              isAFolder: parentNode.type != .root,
                              isRubbishBinFolder: displayMode == .rubbishBin,
                              isViewInFolder: isFromViewInFolder,
                              isIncomingShareChild: isIncomingSharedRootChild,
                              isMyBackupsNode: isMyBackupsNode,
                              isMyBackupsChild: isMyBackupsChild,
                              isOutShare: parentNode.isOutShare(),
                              isExported: parentNode.isExported(),
                              showMediaDiscovery: shouldShowMediaDiscovery())
    }
    
    @objc func setBackupNavigationBarButtons() {
        Task { @MainActor in
            guard let menuConfig = await contextMenuBackupConfiguration() else { return }
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
        }

        if presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.Localizable.close,
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(dismissController))
        }
    }
    
    @objc func showCustomActionsForBackupNode(_ node: MEGANode, sender: Any) {
        Task { @MainActor in
            let myBackupsUseCase = MyBackupsUseCase(myBackupsRepository: MyBackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
            let isBackupNode = await myBackupsUseCase.isBackupNode(node.toNodeEntity())
            showNodeActionsForNode(node, isIncoming: false, isBackupNode: isBackupNode, sender: sender)
        }
    }
    
    @objc func toolbarActionsForNode(_ node: MEGANode) {
        Task { @MainActor in
            guard let parentNode else { return }
            
            let myBackupsUseCase = MyBackupsUseCase(myBackupsRepository: MyBackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
            let isBackupNode = await myBackupsUseCase.isBackupNode(node.toNodeEntity())
            let shareType: MEGAShareType = isBackupNode ? .accessRead : MEGASdkManager.sharedMEGASdk().accessLevel(for: parentNode)
            
            toolbarActions(for: shareType, isBackupNode: isBackupNode)
        }
    }
}
