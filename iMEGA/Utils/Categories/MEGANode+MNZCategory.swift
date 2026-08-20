import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

extension MEGANode {
    /// Whether the node grants the actions the owner has. The SDK reports every node under the Vault as
    /// read-only (except the Password Manager subtree), so backups have to be let in explicitly to keep
    /// their link, sharing and export actions. Write actions stay gated on `isBackupNode` separately.
    @objc var mnz_hasOwnerLevelAccess: Bool {
        MEGASdk.shared.accessLevel(for: self) == .accessOwner || BackupsOCWrapper().isBackupNode(self)
    }
    
    @MainActor
    @objc func pushCloudDriveForNode(_ node: MEGANode, displayMode: DisplayMode, navigationController: UINavigationController) {
        let factory = CloudDriveViewControllerFactory.make(
            nc: navigationController
        )
        let vc = factory.buildBare(
            parentNode: node.toNodeEntity(),
            config: .init(
                displayMode: displayMode
            )
        )
        guard let vc else { return }
        vc.navigationItem.backButtonTitle = ""
        navigationController.pushViewController(vc, animated: false)
    }
    
    @MainActor
    @objc func navigateToParentAndPresent() {
        guard let mainTBC = UIApplication.mainTabBarRootViewController() as? MainTabBarController else { return }

        let parentTreeArray = mnz_parentTreeArray() as? [MEGANode] ?? []
        var backupsRootNode: MEGANode? = BackupRootNodeAccess.shared.isTargetNode(for: self) ? self : nil

        if backupsRootNode == nil {
            for node in parentTreeArray where BackupRootNodeAccess.shared.isTargetNode(for: node) {
                backupsRootNode = node
                break
            }
        }

        let isBackupNode = backupsRootNode != nil

        // Backups are presented in the Cloud Drive tab, and have to be asked for explicitly: the SDK
        // reports every node under the Vault as read-only, so they no longer come in as owner.
        if isBackupNode || MEGASdk.shared.accessLevel(for: self) == .accessOwner {
            mainTBC.selectedIndex = TabManager.driveTabIndex()
        } else {
            navigateToSharedItems(in: mainTBC)
        }

        guard let navigationController = mainTBC.selectedViewController as? UINavigationController else {
            return MEGALogDebug("Trying to navigate to parent of node \(String(describing: self.name)) but selectedViewController is not UINavigationController")
        }

        navigationController.popToRootViewController(animated: false)

        for node in parentTreeArray where node.handle != backupsRootNode?.parentHandle {
            pushCloudDriveForNode(
                node,
                displayMode: isBackupNode ? .backup : .cloudDrive,
                navigationController: navigationController
            )
        }

        switch type {
        case .folder, .rubbish:
            let displayMode: DisplayMode
            let isInRubbish = MEGASdk.shared.isNode(inRubbish: self)
            if isBackupNode {
                displayMode = .backup
            } else {
                displayMode = (type == .rubbish || isInRubbish) ? .rubbishBin : .cloudDrive
            }
            pushCloudDriveForNode(self, displayMode: displayMode, navigationController: navigationController)
            UIApplication.mnz_presentingViewController().dismiss(animated: true)

        case .file:
            if FileExtensionGroupOCWrapper.verify(isVisualMedia: name) {
                guard let parentNode = MEGASdk.shared.node(forHandle: parentHandle) else { return }
                let nodeList = MEGASdk.shared.children(forParent: parentNode)
                let mediaNodesArray = nodeList.mnz_mediaNodesMutableArrayFromNodeList()

                let displayMode: DisplayMode = {
                    if isBackupNode {
                        return .backup
                    } else if MEGASdk.shared.accessLevel(for: self) == .accessOwner {
                        return .cloudDrive
                    } else {
                        return .sharedItem
                    }
                }()

                let photoBrowserVC = MEGAPhotoBrowserViewController.photoBrowser(
                    withMediaNodes: NSMutableArray(array: mediaNodesArray ?? []),
                    api: MEGASdk.shared,
                    displayMode: displayMode,
                    isFromSharedItem: false,
                    presenting: self
                )

                navigationController.present(photoBrowserVC, animated: true)
            } else {
                mnz_open(in: navigationController,
                              folderLink: false,
                              fileLink: nil,
                              messageId: nil,
                              chatId: nil,
                              isFromSharedItem: false,
                              allNodes: nil)
            }

        default:
            UIApplication.mnz_presentingViewController().dismiss(animated: true)
        }
    }

    @MainActor
    private func navigateToSharedItems(in mainTBC: MainTabBarController) {
        mainTBC.selectedIndex = TabManager.menuTabIndex()
        guard let presenter = mainTBC.selectedViewController as? (any AccountMenuItemsNavigating) else {
            return assertionFailure("Trying to navigate to SharedItems screen but selected view controller is not of type AccountMenuItemsNavigating")
        }
        presenter.showSharedItems()
    }
}
