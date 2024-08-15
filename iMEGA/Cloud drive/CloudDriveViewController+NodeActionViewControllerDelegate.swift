import ChatRepo
import MEGADomain
import MEGAPermissions
import MEGASDKRepo

extension CloudDriveViewController: NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) {
        switch action {
        case .download:
            download(nodes)
            toggle(editModeActive: false)
        case .copy:
            showBrowserNavigation(for: nodes, action: .copy)
        case .move:
            prepareToMoveNodes(nodes)
        case .moveToRubbishBin:
            guard let deleteBarButton = sender as? UIBarButtonItem else { return }
            deleteAction(sender: deleteBarButton)
        case .exportFile:
            let entityNodes = nodes.toNodeEntities()
            ExportFileRouter(presenter: self, sender: sender).export(nodes: entityNodes)
            toggle(editModeActive: false)
        case .shareFolder:
            viewModel.openShareFolderDialog(forNodes: nodes)
        case .shareLink, .manageLink:
            presentGetLink(for: nodes)
            toggle(editModeActive: false)
        case .sendToChat:
            showSendToChat(nodes)
            toggle(editModeActive: false)
        case .removeLink:
            let router = ActionWarningViewRouter(presenter: self, nodes: nodes.toNodeEntities(), actionType: .removeLink, onActionStart: {
                SVProgressHUD.show()
            }, onActionFinish: { [weak self] result in
                self?.toggle(editModeActive: false)
                self?.showRemoveLinkResultMessage(result)
            })
                router.start()
        case .saveToPhotos:
            saveToPhotos(nodes: nodes.toNodeEntities())
        case .hide:
            hide(nodes: nodes.toNodeEntities())
            toggle(editModeActive: false)
        case .unhide:
            unhide(nodes: nodes.toNodeEntities())
            toggle(editModeActive: false)
        default:
            break
        }
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        
        switch action {
        case .download:
            download([node])
        case .exportFile:
            exportFile(from: node, sender: sender)
        case .copy:
            showBrowserNavigation(for: [node], action: .copy)
        case .move, .restoreBackup:
            showBrowserNavigation(for: [node], action: .move)
        case .info:
            showNodeInfo(node)
        case .favourite:
            wasSelectingFavoriteUnfavoriteNodeActionOption = true
            MEGASdk.shared.setNodeFavourite(node, favourite: !node.isFavourite)
        case .label:
            node.mnz_labelActionSheet(in: self)
        case .leaveSharing:
            node.mnz_leaveSharing(in: self)
        case .rename:
            node.mnz_renameNode(in: self)
        case .removeLink:
            let router = ActionWarningViewRouter(presenter: self, nodes: [node.toNodeEntity()], actionType: .removeLink, onActionStart: {
                SVProgressHUD.show()
            }, onActionFinish: { [weak self] result in
                self?.showRemoveLinkResultMessage(result)
            })
            router.start()
        case .moveToRubbishBin:
            moveToRubbishBin(for: node)
        case .remove:
            node.mnz_remove(in: self) { [weak self] shouldRemove in
                if shouldRemove {
                    if node.mnz_isPlaying() {
                        AudioPlayerManager.shared.closePlayer()
                    } else if node.isFolder() && self?.parentNode?.handle == node.handle {
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
        case .removeSharing:
            node.mnz_removeSharing()
        case .viewVersions:
            node.mnz_showVersions(in: self)
        case .restore:
            node.mnz_restore()
            
            if node.isFolder() && parentNode?.handle == node.handle {
                navigationController?.popViewController(animated: true)
            }
        case .saveToPhotos:
            saveToPhotos(nodes: [node.toNodeEntity()])
        case .manageShare:
            BackupNodesValidator(presenter: self, nodes: [node.toNodeEntity()]).showWarningAlertIfNeeded { [weak self] in
                self?.manageShare(node)
            }
        case .shareFolder:
            viewModel.openShareFolderDialog(forNodes: [node])
        case .manageLink, .shareLink:
            presentGetLink(for: [node])
        case .sendToChat:
            showSendToChat([node])
        case .editTextFile:
            node.mnz_editTextFile(in: self)
        case .disputeTakedown:
            NSURL(string: MEGADisputeURL)?.mnz_presentSafariViewController()
        case .hide:
            hide(nodes: [node.toNodeEntity()])
        case .unhide:
            unhide(nodes: [node.toNodeEntity()])
        default: break
        }
        
        toggle(editModeActive: false)
    }
        
    func download(_ nodes: [MEGANode]) {
        let transfers = nodes.map { CancellableTransfer(handle: $0.handle, name: nil, appData: nil, priority: false, isFile: $0.isFile(), type: .download) }
        CancellableTransferRouter(presenter: self, transfers: transfers, transferType: .download).start()
    }
    
    func manageShare(_ node: MEGANode) {
        guard let contactsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(identifier: "ContactsViewControllerID") as? ContactsViewController else { return }
        contactsVC.node = node
        contactsVC.contactsMode = .folderSharedWith
        navigationController?.pushViewController(contactsVC, animated: true)
    }
    
    func hide(nodes: [NodeEntity]) {
        viewModel.dispatch(.didTapHideNodes)
        HideFilesAndFoldersRouter(presenter: self)
            .hideNodes(nodes)
    }
    
    func unhide(nodes: [NodeEntity]) {
        let nodeActionUseCase = NodeActionUseCase(repo: NodeActionRepository.newRepo)
        Task {
            _ = await nodeActionUseCase.unhide(nodes: nodes)
        }
    }
    
    private func saveToPhotos(nodes: [NodeEntity]) {
        permissionHandler.photosPermissionWithCompletionHandler { [weak self] granted in
            guard let self else { return }
            
            guard granted else {
                permissionRouter.alertPhotosPermission()
                return
            }
            
            let saveMediaUseCase = SaveMediaToPhotosUseCase(downloadFileRepository: DownloadFileRepository(sdk: MEGASdk.shared), fileCacheRepository: FileCacheRepository.newRepo, nodeRepository: NodeRepository.newRepo, chatNodeRepository: ChatNodeRepository.newRepo, downloadChatRepository: DownloadChatRepository.newRepo)
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
                        UIImage(resource: .saveToPhotos),
                        status: error.localizedDescription
                    )
                }
            }
        }
    }
    
    private func showRemoveLinkResultMessage(_ result: Result<String, RemoveLinkErrorEntity>) {
        switch result {
        case .success(let message):
            SVProgressHUD.showSuccess(withStatus: message)
        case .failure:
            SVProgressHUD.dismiss()
        }
    }
}
