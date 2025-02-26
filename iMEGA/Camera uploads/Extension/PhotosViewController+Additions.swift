import ChatRepo
import MEGADesignToken
import MEGADomain
import MEGAPermissions
import MEGAPresentation
import MEGASDKRepo

extension PhotosViewController {
    
    var permissionHandler: any DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }
    
    var permissionRouter: some PermissionAlertRouting {
        PermissionAlertRouter.makeRouter(deviceHandler: permissionHandler)
    }
        
    func handleDownloadAction(for nodes: [MEGANode]) {

        let transfers = nodes.map {
            CancellableTransfer(handle: $0.handle, name: nil, appData: nil, priority: false, isFile: $0.isFile(), type: .download)
        }
        CancellableTransferRouter(presenter: self, transfers: transfers, transferType: .download).start()
        toggleEditing()
    }
    
    func showBrowserNavigation(for nodes: [MEGANode], action: BrowserAction) {
        guard let navigationController = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController,
              let browserVC = navigationController.viewControllers.first as? BrowserViewController else {
            return
        }
        browserVC.browserViewControllerDelegate = self
        browserVC.selectedNodesArray = nodes
        browserVC.browserAction = action
        present(navigationController, animated: true)
    }
    
    func handleShareLink(for nodes: [MEGANode]) {
        guard MEGAReachabilityManager.isReachableHUDIfNot() else { return }
        GetLinkRouter(presenter: UIApplication.mnz_presentingViewController(),
                      nodes: nodes).start()
        toggleEditing()
    }
    
    func handleDeleteAction(for nodes: [MEGANode]) {
        guard let rubbish = MEGASdk.sharedSdk.rubbishNode else { return }
        let delegate = MEGAMoveRequestDelegate(toMoveToTheRubbishBinWithFiles: nodes.contentCounts().fileCount,
                                               folders: nodes.contentCounts().folderCount) { [weak self] in
            self?.toggleEditing()
        }
        nodes.forEach { MEGASdk.sharedSdk.move($0, newParent: rubbish, delegate: delegate) }
    }
    
    func handleRemoveLinks(for nodes: [MEGANode]) {
        let router = ActionWarningViewRouter(presenter: self, nodes: nodes.toNodeEntities(), actionType: .removeLink, onActionStart: {
            SVProgressHUD.show()
        }, onActionFinish: { [weak self] result in
            self?.toggleEditing()
            switch result {
            case .success(let message):
                SVProgressHUD.showSuccess(withStatus: message)
            case .failure:
                SVProgressHUD.dismiss()
            }
        })
        router.start()
    }
    
    private func handleExportFile(for nodes: [MEGANode], sender: Any) {
        let entityNodes = nodes.toNodeEntities()
        ExportFileRouter(presenter: self, sender: sender).export(nodes: entityNodes)
        toggleEditing()
    }
    
    private func handleSendToChat(for nodes: [MEGANode]) {
        guard let navigationController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController,
              let sendToViewController = navigationController.viewControllers.first as? SendToViewController else {
            return
        }
        
        sendToViewController.nodes = nodes
        sendToViewController.sendMode = .cloud
        present(navigationController, animated: true)
        toggleEditing()
    }
    
    private func handleSaveToPhotos(for nodes: [MEGANode]) {
        permissionHandler.photosPermissionWithCompletionHandler { [weak self] granted in
            guard let self else { return }
            
            guard granted else {
                permissionRouter.alertPhotosPermission()
                return
            }
            
            let saveMediaUseCase = SaveMediaToPhotosUseCase(downloadFileRepository: DownloadFileRepository(sdk: MEGASdk.sharedSdk),
                                                            fileCacheRepository: FileCacheRepository.newRepo, nodeRepository: NodeRepository.newRepo, chatNodeRepository: ChatNodeRepository.newRepo, downloadChatRepository: DownloadChatRepository.newRepo)
            Task { @MainActor in
                do {
                    try await saveMediaUseCase.saveToPhotos(nodes: nodes.toNodeEntities())
                } catch {
                    guard let errorEntity = error as? SaveMediaToPhotosErrorEntity,
                          errorEntity != .cancelled  else {
                        return
                    }
                    
                    await SVProgressHUD.dismiss()
                    SVProgressHUD.show(
                        UIImage(resource: .saveToPhotos),
                        status: error.localizedDescription
                    )
                }
                self.toggleEditing()
            }
        }
    }
    
    private func hide(nodes: [NodeEntity]) {
        viewModel.trackHideNodeMenuEvent()
        
        HideFilesAndFoldersRouter(presenter: self)
            .hideNodes(nodes)
        
        self.toggleEditing()
    }
    
    private func unhide(nodes: [NodeEntity]) {
        Task {
            let nodeActionUseCase = NodeActionUseCase(repo: NodeActionRepository.newRepo)
            _ = await nodeActionUseCase.unhide(nodes: nodes)
        }
        self.toggleEditing()
    }
    
    @objc func isTimelineActive() -> Bool {
        parentPhotoAlbumsController?.isTimelineActive() ?? false
    }
    
    func addToAlbum(nodes: [NodeEntity]) {
        AddToCollectionRouter(
            presenter: self,
            mode: .album,
            selectedPhotos: nodes).start()
        
        toggleEditing()
    }
}

// MARK: - NodeActionViewControllerDelegate
extension PhotosViewController: NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) {
        handleNodesAction(action: action, nodes: nodes, sender: sender)
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        handleNodesAction(action: action, nodes: [node], sender: sender)
    }

    private func handleNodesAction(action: MegaNodeActionType, nodes: [MEGANode], sender: Any) {
        switch action {
        case .download:
            handleDownloadAction(for: nodes)
        case .copy:
            showBrowserNavigation(for: nodes, action: .copy)
        case .move:
            showBrowserNavigation(for: nodes, action: .move)
        case .shareLink, .manageLink:
            handleShareLink(for: nodes)
        case .moveToRubbishBin:
            handleDeleteAction(for: nodes)
        case .exportFile:
            handleExportFile(for: nodes, sender: sender)
        case .sendToChat:
            handleSendToChat(for: nodes)
        case .removeLink:
            handleRemoveLinks(for: nodes)
        case .saveToPhotos:
            handleSaveToPhotos(for: nodes)
        case .hide:
            hide(nodes: nodes.toNodeEntities())
        case .unhide:
            unhide(nodes: nodes.toNodeEntities())
        case .addToAlbum:
            addToAlbum(nodes: nodes.toNodeEntities())
        default:
            break
        }
    }
}

// MARK: - BrowserViewControllerDelegate and ContactsViewControllerDelegate
extension PhotosViewController: BrowserViewControllerDelegate, ContactsViewControllerDelegate {
    public func nodeEditCompleted(_ complete: Bool) {
        toggleEditing()
    }
}

extension PhotosViewController {
    @objc func configureStackViewHeight(view: UIView, perviousConstraint: NSLayoutConstraint?) -> NSLayoutConstraint? {

        var newConstraint: NSLayoutConstraint?
        let verticalPadding = 24.0

        let maxHeight = view.subviews.flatMap({ $0.subviews }).map({ $0.intrinsicContentSize.height }).max() ?? 0

        if perviousConstraint == nil {
            newConstraint = view.heightAnchor.constraint(equalToConstant: maxHeight > 0 ? maxHeight + verticalPadding : 0)
        } else {
            perviousConstraint?.isActive = false
            newConstraint = view.heightAnchor.constraint(equalToConstant: maxHeight + verticalPadding)
        }
        newConstraint?.isActive = true
        return newConstraint
    }
}
