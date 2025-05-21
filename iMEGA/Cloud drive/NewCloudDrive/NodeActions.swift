import ChatRepo
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPreference

/// Place to store all node actions instead of injecting tens of closures directly into the factory
/// It's  injected to CloudDriveFactory from the outside as it mostly needs
/// parentViewController and a node or array of nodes
/// More complex logic should be moved their own routers (move to bin, delete from bin)
struct NodeActions {
    var nodeDownloader: ([NodeEntity]) -> Void
    var editTextFile: (NodeEntity) -> Void
    var shareOrManageLink: ([NodeEntity]) -> Void
    var showNodeInfo: (NodeEntity) -> Void
    var assignLabel: (NodeEntity) -> Void
    var toggleNodeFavourite: (NodeEntity) -> Void
    var sendToChat: ([NodeEntity]) -> Void
    var saveToPhotos: ([NodeEntity]) -> Void
    var exportFiles: (_ nodes: [NodeEntity], _ sender: Any) -> Void
    // this is used to move or copy a node
    var browserAction: (_ action: BrowserActionEntity, _ nodes: [NodeEntity]) -> Void
    var userProfileOpener: (UINavigationController) -> Void
    var removeLink: ([NodeEntity]) -> Void
    var removeSharing: (NodeEntity) -> Void
    
    // second argument should be called to trigger NavBar title refresh
    var rename: (_ node: NodeEntity, _ nameChanged: @escaping () -> Void) -> Void
    var shareFolders: ([NodeEntity]) -> Void
    var leaveSharing: (NodeEntity) -> Void
    var manageShare: ([NodeEntity]) -> Void
    
    var showNodeVersions: (NodeEntity) -> Void
    // this is handling rubbish bin action
    
    var disputeTakedown: (NodeEntity) -> Void
    
    var moveToRubbishBin: ([NodeEntity]) -> Void
    var restoreFromRubbishBin: ([NodeEntity]) -> Void
    var removeFromRubbishBin: ([NodeEntity]) -> Void
    
    var hide: ([NodeEntity]) -> Void
    var unhide: ([NodeEntity]) -> Void
    
    var addToAlbum: ([NodeEntity]) -> Void
    var addTo: ([NodeEntity]) -> Void
}

// Disabling cyclomatic check as this right now
// has all the actions that can be made on nodes in the cloud drive
// Previously this was sprinkled around tens of files with CloudDriveViewController
// making it tightly coupled to tens of other classes
// All actions triggered on new Cloud Drive are stored here, but there's a possibility of a better
// structure that more composable and extensible

// swiftlint:disable cyclomatic_complexity
extension NodeActions {
    
    private static func megaNodes(
        from nodeEntities: [NodeEntity],
        using sdk: MEGASdk
    ) -> [MEGANode] {
        nodeEntities.compactMap {
            sdk.node(forHandle: $0.handle)
        }
    }
    
    static func makeActions(
        sdk: MEGASdk,
        navigationController: UINavigationController
    ) -> NodeActions {
        .init(
            nodeDownloader: { nodes in
                
                let transfers = nodes.map {
                    CancellableTransfer(
                        handle: $0.handle,
                        name: nil,
                        appData: nil,
                        priority: false,
                        isFile: $0.isFile,
                        type: .download
                    )
                }
                
                CancellableTransferRouter(
                    presenter: navigationController,
                    transfers: transfers,
                    transferType: .download
                ).start()
            },
            editTextFile: { node in
                if let megaNode = sdk.node(forHandle: node.handle) {
                    megaNode.mnz_editTextFile(in: navigationController)
                }
            },
            shareOrManageLink: { nodes in
                guard nodes.isNotEmpty else {
                    assertionFailure("Cannot pass empty array of nodes to GetLinkRouter")
                    MEGALogError("Passed empty array of nodes to GetLinkRouter")
                    return
                }
                GetLinkRouter(
                    presenter: navigationController,
                    nodes: nodes.compactMap { sdk.node(forHandle: $0.handle) }
                ).start()
            },
            showNodeInfo: { node in
                Task { @MainActor in
                    let nodeInfoRouter = NodeInfoRouter(navigationController: navigationController, contacstUseCase: ContactsUseCase(repository: ContactsRepository.newRepo))
                    nodeInfoRouter.showInformation(for: node)
                }
            },
            assignLabel: { node in
                guard let megaNode = sdk.node(forHandle: node.handle) else { return }
                megaNode.mnz_labelActionSheet(in: navigationController)
            },
            toggleNodeFavourite: { node in
                guard let megaNode = sdk.node(forHandle: node.handle) else { return }
                sdk.setNodeFavourite(megaNode, favourite: !megaNode.isFavourite)
            },
            sendToChat: { nodes in
                guard let localNavController =
                        UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController, let sendToViewController = localNavController.viewControllers.first as? SendToViewController else {
                    return
                }
                
                sendToViewController.nodes = megaNodes(from: nodes, using: sdk)
                sendToViewController.sendMode = .cloud
                
                navigationController.present(localNavController, animated: true)
            },
            saveToPhotos: { nodes in
                
                let handler = DevicePermissionsHandler.makeHandler()
                let permissionRouter = PermissionAlertRouter.makeRouter(deviceHandler: handler)
                
                handler.photosPermissionWithCompletionHandler { granted in
                    guard granted else {
                        permissionRouter.alertPhotosPermission()
                        return
                    }
                    
                    let saveMediaUseCase = SaveMediaToPhotosUseCase(
                        downloadFileRepository: DownloadFileRepository(sdk: sdk),
                        fileCacheRepository: FileCacheRepository.newRepo,
                        nodeRepository: NodeRepository.newRepo,
                        chatNodeRepository: ChatNodeRepository.newRepo,
                        downloadChatRepository: DownloadChatRepository.newRepo
                    )
                    Task { @MainActor in
                        do {
                            try await saveMediaUseCase.saveToPhotos(nodes: nodes)
                        } catch {
                            guard let errorEntity = error as? SaveMediaToPhotosErrorEntity,
                                  errorEntity != .cancelled  else {
                                return
                            }
                            
                            await SVProgressHUD.dismiss()
                            SVProgressHUD.show(
                                MEGAAssets.UIImage.saveToPhotos,
                                status: error.localizedDescription
                            )
                        }
                    }
                }
            },
            exportFiles: { nodes, sender in
                Task { @MainActor in
                    let router = ExportFileRouter(
                        presenter: navigationController,
                        sender: sender
                    )
                    router.export(nodes: nodes)
                }
            },
            browserAction: { action, nodes in
                guard let localNC = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController,
                      let browserVC = localNC.viewControllers.first as? BrowserViewController else {
                    return
                }
                // this is missing , to be implemented in [FM-1824]
                // browserVC.browserViewControllerDelegate = browseDelegate
                browserVC.selectedNodesArray = megaNodes(from: nodes, using: sdk)
                if action == .move {
                    browserVC.browserAction = .move
                } else if action == .copy {
                    browserVC.browserAction = .copy
                } else {
                    assertionFailure("here only copy and move is supported")
                }
                navigationController.present(localNC, animated: true)
            },
            userProfileOpener: { navigationController in
                MyAccountHallRouter(
                    myAccountHallUseCase: MyAccountHallUseCase(repository: AccountRepository.newRepo),
                    purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo), 
                    accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                    accountStorageUseCase: AccountStorageUseCase(
                        accountRepository: AccountRepository.newRepo,
                        preferenceUseCase: PreferenceUseCase.default
                    ),
                    shareUseCase: ShareUseCase(
                        shareRepository: ShareRepository.newRepo,
                        filesSearchRepository: FilesSearchRepository.newRepo,
                        nodeRepository: NodeRepository.newRepo),
                    networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
                    notificationsUseCase: NotificationsUseCase(repository: NotificationsRepository.newRepo),
                    navigationController: navigationController
                ).start()
            },
            removeLink: { nodes in
                let router = ActionWarningViewRouter(
                    presenter: navigationController,
                    nodes: nodes,
                    actionType: .removeLink,
                    onActionStart: { SVProgressHUD.show() },
                    onActionFinish: {
                        switch $0 {
                        case .success(let message):
                            SVProgressHUD.showSuccess(withStatus: message)
                        case .failure:
                            SVProgressHUD.dismiss()
                        }
                    })
                router.start()
            },
            removeSharing: { node in
                guard
                    let megaNode = sdk.node(forHandle: node.handle)
                else { return }
                
                megaNode.mnz_removeSharing { [weak navigationController] completed in
                    if completed {
                        navigationController?.popViewController(animated: true)
                    }
                }
            },
            rename: { node, triggerNameChanged in
                guard
                    let megaNode = sdk.node(forHandle: node.handle)
                else { return }
                megaNode.mnz_renameNode(in: navigationController) { request in
                    if request.name != nil {
                        triggerNameChanged()
                    }
                }
            },
            shareFolders: { nodes in
                Task { @MainActor in
                    let sharedItemsRouter = SharedItemsViewRouter()
                    let shareUseCase = ShareUseCase(
                        shareRepository: ShareRepository.newRepo,
                        filesSearchRepository: FilesSearchRepository.newRepo,
                        nodeRepository: NodeRepository.newRepo)
                    
                    do {
                        _ = try await shareUseCase.createShareKeys(forNodes: nodes)
                        sharedItemsRouter.showShareFoldersContactView(withNodes: nodes)
                    } catch {
                        SVProgressHUD.showError(withStatus: error.localizedDescription)
                    }
                }
            },
            leaveSharing: { node in
                guard
                    let megaNode = sdk.node(forHandle: node.handle)
                else { return }
                megaNode.mnz_leaveSharing(in: navigationController) { [weak navigationController] actionCompleted in
                    if actionCompleted {
                        navigationController?.popViewController(animated: true)
                    }
                }
            },
            manageShare: { nodes in
                Task { @MainActor in
                    // check multi node
                    guard let node = nodes.first else { return }
                    let nodeShareRouter = NodeShareRouter(viewController: navigationController)
                    nodeShareRouter.pushManageSharing(for: node, on: navigationController)
                }
            },
            
            showNodeVersions: { node in
                guard
                    let megaNode = sdk.node(forHandle: node.handle)
                else { return }
                megaNode.mnz_showVersions(in: navigationController)
            },
            disputeTakedown: { _ in
                NSURL(string: MEGADisputeURL)?.mnz_presentSafariViewController()
            },
            moveToRubbishBin: { nodes in
                moveNodesToRubbishBin(nodes, presenter: navigationController)
            },
            restoreFromRubbishBin: { nodes in
                let megaNodes = megaNodes(from: nodes, using: sdk)
                for megaNode in megaNodes {
                    megaNode.mnz_restore()
                }
            },
            removeFromRubbishBin: { nodes in
                confirmDeleteActionFiles(
                    selectedNodes: nodes,
                    sdk: sdk,
                    parent: navigationController
                )
            },
            hide: { nodes in
                Task { @MainActor in
                    HideFilesAndFoldersRouter(presenter: navigationController).hideNodes(nodes)
                }
            },
            unhide: { nodes in
                Task { @MainActor in
                    HideFilesAndFoldersRouter(presenter: navigationController)
                        .unhideNodes(nodes)
                }
                
            },
            addToAlbum: {
                AddToCollectionRouter(
                    presenter: navigationController,
                    mode: .album,
                    selectedPhotos: $0).start()
            },
            addTo: {
                AddToCollectionRouter(
                    presenter: navigationController,
                    mode: .collection,
                    selectedPhotos: $0).start()
            }
        )
    }
    
    static func moveNodesToRubbishBin(_ nodes: [NodeEntity], presenter: UIViewController) {
        checkIfCameraUploadPromptIsNeeded(selectedNodes: nodes, sdk: MEGASdk.shared) { shouldPrompt in
            DispatchQueue.main.async {
                if shouldPrompt {
                    promptCameraUploadFolderDeletion(parent: presenter) {
                        moveSelectedNodesToRubbishBin(selectedNodes: nodes, sdk: MEGASdk.shared)
                    }
                } else {
                    moveSelectedNodesToRubbishBin(selectedNodes: nodes, sdk: MEGASdk.shared)
                }
            }
        }
    }
    
    private static func confirmDeleteActionFiles(
            selectedNodes: [NodeEntity],
            sdk: MEGASdk,
            parent: UIViewController
        ) {
            let mageNodes = megaNodes(from: selectedNodes, using: sdk)
            let filesCount = mageNodes.contentCounts().fileCount
            let foldersCount = mageNodes.contentCounts().folderCount
            
            let executePermanentRemoval = {
                deleteFromRubbishBin(
                    selectedNodes: selectedNodes,
                    numFiles: filesCount,
                    numFolders: foldersCount,
                    sdk: sdk
                )
            }
    
            if filesCount > 0 || foldersCount > 0 {
                let alertTitle = alertTitle(forRemovedFiles: Int(filesCount), andFolders: Int(foldersCount)) ?? ""
                let alertMessage = alertMessage(forRemovedFiles: Int(filesCount), andFolders: Int(foldersCount))
                let alert = UIAlertController(title: alertTitle,
                                              message: alertMessage,
                                              preferredStyle: .alert)
                alert.addAction(.init(title: Strings.Localizable.cancel, style: .cancel, handler: nil))
    
                alert.addAction(.init(title: Strings.Localizable.ok, style: .default) { _ in
                    executePermanentRemoval()
                })
    
                parent.present(alert, animated: true)
            } else {
                executePermanentRemoval()
            }
        }
    
        private static func deleteFromRubbishBin(
            selectedNodes: [NodeEntity],
            numFiles: UInt,
            numFolders: UInt,
            sdk: MEGASdk
        ) {
    
            guard let delegate = MEGARemoveRequestDelegate(mode: DisplayMode.rubbishBin.rawValue, files: numFiles, folders: numFolders, completion: {
                // not sure if this should trigger some completion
                // check in [FM-1824]
            }) else { return }
    
            let mageNodes = megaNodes(from: selectedNodes, using: sdk)
    
            for node in mageNodes {
                sdk.remove(node, delegate: delegate)
            }
        }
    
        private static func alertMessage(
            forRemovedFiles fileCount: Int,
            andFolders folderCount: Int
        ) -> String {
            return String.inject(plurals: [
                .init(count: fileCount, localize: Strings.Localizable.SharedItems.Rubbish.Warning.fileCount),
                .init(count: folderCount, localize: Strings.Localizable.SharedItems.Rubbish.Warning.folderCount)
            ], intoLocalized: Strings.Localizable.SharedItems.Rubbish.Warning.message)
        }
    
        private static func alertTitle(
            forRemovedFiles fileCount: Int,
            andFolders folderCount: Int
        ) -> String? {
            guard fileCount > 1 else { return nil }
            return Strings.Localizable.removeNodeFromRubbishBinTitle
        }
    
    private static func checkIfCameraUploadPromptIsNeeded(
        selectedNodes: [NodeEntity],
        sdk: MEGASdk,
        completion: @escaping (Bool) -> Void
    ) {
        let mageNodes = megaNodes(from: selectedNodes, using: sdk)
        
        CameraUploadNodeAccess.shared.loadNode { node, _ in
            guard let cuNode = node else {
                completion(false)
                return
            }
            
            let isSelected = mageNodes.contains {
                cuNode.isDescendant(of: $0, in: sdk)
            }
            
            completion(isSelected)
        }
    }
    
    private static func promptCameraUploadFolderDeletion(
        parent: UIViewController,
        deleteHandler: @escaping () -> Void,
        cancelHandler: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: Strings.Localizable.General.MenuAction.moveToRubbishBin,
            message: Strings.Localizable.areYouSureYouWantToMoveCameraUploadsFolderToRubbishBinIfSoANewFolderWillBeAutoGeneratedForCameraUploads,
            preferredStyle: .alert
        )
        alert.addAction(.init(title: Strings.Localizable.cancel, style: .cancel) { _ in
            cancelHandler?()
        })
        
        alert.addAction(.init(title: Strings.Localizable.ok, style: .default) { _ in
            deleteHandler()
        })
        
        parent.present(alert, animated: true)
    }
    
    private static func moveSelectedNodesToRubbishBin(
        selectedNodes: [NodeEntity],
        sdk: MEGASdk
    ) {
        let megaNodes = megaNodes(from: selectedNodes, using: sdk)
        
        guard let rubbish = sdk.rubbishNode else {
            return
        }
        
        let delegate = MEGAMoveRequestDelegate(
            toMoveToTheRubbishBinWithFiles: megaNodes.contentCounts().fileCount,
            folders: megaNodes.contentCounts().folderCount
        ) {
            // not sure if this should trigger some completion
            // check in [FM-1824]
        }
        
        for node in megaNodes {
            sdk.move(node, newParent: rubbish, delegate: delegate)
        }
        
    }
}
// swiftlint:enable cyclomatic_complexity
