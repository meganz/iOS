import ChatRepo
import ContentLibraries
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGASDKRepo
import UIKit

protocol AlbumToolbarProvider {
    var isToolbarShown: Bool { get }
    
    func showToolbar()
    func hideToolbar()
    func configureToolbarButtons(albumType: AlbumType)
    func downloadButtonPressed(_ button: UIBarButtonItem)
    func shareLinkButtonPressed(_ button: UIBarButtonItem)
    func favouriteButtonPressed(_ button: UIBarButtonItem)
    func deleteButtonPressed(_ button: UIBarButtonItem)
    func moreButtonPressed(_ button: UIBarButtonItem)
}

extension AlbumContentViewController: AlbumToolbarProvider {
    var permissionHandler: any DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }
    
    var permissionRouter: some PermissionAlertRouting {
        PermissionAlertRouter.makeRouter(deviceHandler: permissionHandler)
    }
    
    var isToolbarShown: Bool {
        return toolbar.superview != nil
    }
    
    func showToolbar() {
        toolbar.alpha = 0.0
        view.addSubview(toolbar)
        
        let bottomAnchor: NSLayoutYAxisAnchor = view.safeAreaLayoutGuide.bottomAnchor
        let leadingAnchor: NSLayoutXAxisAnchor = view.safeAreaLayoutGuide.leadingAnchor
        let trailingAnchor: NSLayoutXAxisAnchor = view.safeAreaLayoutGuide.trailingAnchor
        
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.backgroundColor = TokenColors.Background.surface1
        toolbar.heightAnchor.constraint(equalToConstant: 64.0).isActive = true
        toolbar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        toolbar.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        toolbar.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        UIView.animate(withDuration: 0.3) {
            self.toolbar.alpha = 1.0
        }
    }
    
    func hideToolbar() {
        guard toolbar.superview != nil else { return }
        UIView.animate(withDuration: 0.3) {
            self.toolbar.alpha = 0.0
        } completion: { _ in
            self.toolbar.removeFromSuperview()
        }
    }
    
    func configureToolbarButtons(albumType: AlbumType) {
        if albumToolbarConfigurator == nil {
            albumToolbarConfigurator = AlbumToolbarConfigurator(
                downloadAction: downloadButtonPressed,
                shareLinkAction: shareLinkButtonPressed,
                moveAction: moveBarButtonPressed,
                copyAction: copyBarButtonPressed,
                deleteAction: deleteButtonPressed,
                favouriteAction: favouriteButtonPressed,
                removeToRubbishBinAction: deleteButtonPressed,
                exportAction: didPressedExportFile,
                sendToChatAction: didPressedSendToChat,
                moreAction: moreButtonPressed,
                albumType: albumType
            )
        }
        
        toolbar.items = albumToolbarConfigurator?.toolbarItems(forNodes: selectedNodes())
    }
    
    // MARK: - Toolbar Button actions
    func downloadButtonPressed(_ button: UIBarButtonItem) {
        viewModel.dispatch(.downloadButtonTap)
    }
    
    func shareLinkButtonPressed(_ button: UIBarButtonItem) {
        viewModel.dispatch(.sharePhotoLinksTap)
    }
    
    func moveBarButtonPressed(_ button: UIBarButtonItem) {
        openBrowserViewController(withAction: .move)
    }
    
    func copyBarButtonPressed(_ button: UIBarButtonItem) {
        openBrowserViewController(withAction: .copy)
    }
    
    func deleteButtonPressed(_ button: UIBarButtonItem) {
        viewModel.dispatch(.deletePhotosTap)
    }
    
    func moreButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        let nodeActionsViewController = NodeActionViewController(nodes: selectedNodes,
                                                                 delegate: self,
                                                                 displayMode: viewModel.isFavouriteAlbum ? .photosFavouriteAlbum : .photosAlbum,
                                                                 sender: button)
        nodeActionsViewController.accessoryActionDelegate = nodeAccessoryActionDelegate
        present(nodeActionsViewController, animated: true, completion: nil)
    }
    
    func didPressedExportFile(_ button: UIBarButtonItem) {
        viewModel.dispatch(.exportFilesTap(sender: button))
    }
    
    func didPressedSendToChat(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        guard let navigationController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController,
              let sendToViewController = navigationController.viewControllers.first as? SendToViewController else {
            return
        }
        
        sendToViewController.nodes = selectedNodes
        sendToViewController.sendMode = .cloud
        present(navigationController, animated: true)
        endEditingMode()
    }
    
    func favouriteButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty
        else {
            return
        }
        
        let favoriteUseCase = NodeFavouriteActionUseCase(nodeFavouriteRepository: NodeFavouriteActionRepository.newRepo)
        
        selectedNodes.forEach { node in
            if node.isFavourite {
                Task {
                    try await favoriteUseCase.unFavourite(node: node.toNodeEntity())
                }
            } else {
                Task {
                    try await favoriteUseCase.favourite(node: node.toNodeEntity())
                }
            }
        }
        
        endEditingMode()
    }
    
    func saveToPhotosButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
                  return
              }
        
        endEditingMode()
        
        permissionHandler.photosPermissionWithCompletionHandler { [weak self] granted in
            guard let self else { return }
            
            guard granted else {
                permissionRouter.alertPhotosPermission()
                return
            }
            
            let saveMediaUseCase = SaveMediaToPhotosUseCase(downloadFileRepository: DownloadFileRepository(sdk: MEGASdk.shared),
                                                            fileCacheRepository: FileCacheRepository.newRepo,
                                                            nodeRepository: NodeRepository.newRepo,
                                                            chatNodeRepository: ChatNodeRepository.newRepo, 
                                                            downloadChatRepository: DownloadChatRepository.newRepo)
            
            TransfersWidgetViewController.sharedTransfer().setProgressViewInKeyWindow()
            TransfersWidgetViewController.sharedTransfer().progressView?.showWidgetIfNeeded()
            TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
            
            Task { @MainActor in
                do {
                    try await saveMediaUseCase.saveToPhotos(nodes: selectedNodes.toNodeEntities())
                } catch {
                    
                    guard let errorEntity = error as? SaveMediaToPhotosErrorEntity,
                          errorEntity != .cancelled else {
                        return
                    }
                    
                    await SVProgressHUD.dismiss()
                    SVProgressHUD.show(
                        UIImage.saveToPhotos,
                        status: error.localizedDescription
                    )
                }
            }
        }
    }
    
    // MARK: - Private
    
    private func openBrowserViewController(withAction action: BrowserAction) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty,
              let navigationController = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController,
              let browserVC = navigationController.viewControllers.first as? BrowserViewController else {
                  return
              }
        
        browserVC.selectedNodesArray = selectedNodes
        browserVC.browserAction = action
        browserVC.browserViewControllerDelegate = self
        present(navigationController, animated: true)
    }
    
    private func downloadStarted(forNode node: MEGANode) { }
}

// MARK: - NodeActionViewControllerDelegate
extension AlbumContentViewController: NodeActionViewControllerDelegate {
    func nodeAction(
        _ nodeAction: NodeActionViewController,
        didSelect action: MegaNodeActionType,
        forNodes nodes: [MEGANode],
        from sender: Any
    ) {
        handleNodesAction(action: action, nodes: nodes, sender: sender)
    }
    
    func nodeAction(
        _ nodeAction: NodeActionViewController,
        didSelect action: MegaNodeActionType,
        for node: MEGANode,
        from sender: Any
    ) {
        handleNodesAction(action: action, nodes: [node], sender: sender)
    }

    private func handleNodesAction(
        action: MegaNodeActionType,
        nodes: [MEGANode],
        sender: Any
    ) {
        guard let sender = sender as? UIBarButtonItem else { return }
        switch action {
        case .download:
            downloadButtonPressed(sender)
        case .copy:
            copyBarButtonPressed(sender)
        case .move:
            moveBarButtonPressed(sender)
        case .shareLink:
            shareLinkButtonPressed(sender)
        case .moveToRubbishBin:
            deleteButtonPressed(sender)
        case .exportFile:
            didPressedExportFile(sender)
        case .sendToChat:
            didPressedSendToChat(sender)
        case .favourite:
            favouriteButtonPressed(sender)
        case .saveToPhotos:
            saveToPhotosButtonPressed(sender)
        case .hide:
            hide(nodes: nodes.toNodeEntities())
        case .unhide:
            unhide(nodes: nodes.toNodeEntities())
        default:
            break
        }
    }
    
    private func hide(nodes: [NodeEntity]) {
        viewModel.dispatch(.hideNodes)
        
        HideFilesAndFoldersRouter(presenter: self)
            .hideNodes(nodes)
        
        endEditingMode()
    }
    
    private func unhide(nodes: [NodeEntity]) {
        HideFilesAndFoldersRouter(presenter: self)
            .unhideNodes(nodes)
        
        endEditingMode()
    }
}

// MARK: - BrowserViewControllerDelegate
extension AlbumContentViewController: BrowserViewControllerDelegate {
    func nodeEditCompleted(_ complete: Bool) {
        endEditingMode()
    }
}
