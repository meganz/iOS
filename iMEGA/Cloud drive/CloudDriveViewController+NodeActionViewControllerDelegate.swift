import MEGADomain

extension CloudDriveViewController: NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) ->  () {
        switch action {
        case .download:
            download(nodes)
            setEditMode(false)
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
            setEditMode(false)
        case .shareFolder:
            showShareFolderForNodes(nodes)
        case .shareLink, .manageLink:
            presentGetLinkVC(for: nodes)
            setEditMode(false)
        case .sendToChat:
            showSendToChat(nodes)
            setEditMode(false)
        case .removeLink:
            removeLinksForNodes(nodes)
            setEditMode(false)
        default:
            break
        }
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        setEditMode(false)
        
        switch (action) {
        case .download:
            download([node])
        case .exportFile:
            exportFile(from: node, sender: sender)
        case .copy:
            showBrowserNavigation(for: [node], action: .copy)
        case .move:
            showBrowserNavigation(for: [node], action: .move)
        case .info:
            showNodeInfo(node)
        case .favourite:
            if #available(iOS 14.0, *) {
                MEGASdkManager.sharedMEGASdk().setNodeFavourite(node, favourite: !node.isFavourite, delegate: MEGAGenericRequestDelegate(completion: { (request, error) in
                    if error.type == .apiOk {
                        request.numDetails == 1 ? QuickAccessWidgetManager().insertFavouriteItem(for: node) :
                                                  QuickAccessWidgetManager().deleteFavouriteItem(for: node)
                    }
                }))
            } else {
                MEGASdkManager.sharedMEGASdk().setNodeFavourite(node, favourite: !node.isFavourite)
            }
        case .label:
            node.mnz_labelActionSheet(in: self)
        case .leaveSharing:
            node.mnz_leaveSharing(in: self)
        case .rename:
            node.mnz_renameNode(in: self)
        case .removeLink:
            node.mnz_removeLink()
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
            TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
            SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: Strings.Localizable.savingToPhotos)
            
            let saveMediaUseCase = SaveMediaToPhotosUseCase(downloadFileRepository: DownloadFileRepository(sdk: MEGASdkManager.sharedMEGASdk()), fileCacheRepository: FileCacheRepository.newRepo, nodeRepository: NodeRepository.newRepo)
            
            saveMediaUseCase.saveToPhotos(node: node.toNodeEntity()) { result in
                if case let .failure(error) = result, error != .cancelled {
                    SVProgressHUD.dismiss()
                    SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: Strings.Localizable.somethingWentWrong)
                }
            }
        case .manageShare:
            manageShare(node)
        case .shareFolder:
            showShareFolderForNodes([node])
        case .manageLink, .shareLink:
            presentGetLinkVC(for: [node])
        case .sendToChat:
            showSendToChat([node])
        case .editTextFile:
            node.mnz_editTextFile(in: self)
        case .disputeTakedown:
            NSURL(string: MEGADisputeURL)?.mnz_presentSafariViewController()
        default: break
        }
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
}
