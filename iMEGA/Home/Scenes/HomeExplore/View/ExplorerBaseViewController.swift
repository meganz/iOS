import ChatRepo
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAPhotos
import MEGASDKRepo
import MEGAUIKit

class ExplorerBaseViewController: UIViewController {
    lazy var toolbar = UIToolbar()
    lazy var nodeAccessoryActionDelegate = DefaultNodeAccessoryActionDelegate()
    private var explorerToolbarConfigurator: ExplorerToolbarConfigurator?
    
    var isToolbarShown: Bool {
        return toolbar.superview != nil
    }
    
    var displayMode: DisplayMode { .unknown }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isToolbarShown {
            endEditingMode()
        }
    }
    
    func showToolbar() {
        guard let tabBarController = tabBarController, toolbar.superview == nil else { return }
        
        if !tabBarController.view.subviews.contains(toolbar) {
            toolbar.alpha = 0.0
            tabBarController.view.addSubview(toolbar)
            toolbar.backgroundColor = TokenColors.Background.surface1
            toolbar.translatesAutoresizingMaskIntoConstraints = false
            toolbar.topAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor).isActive = true
            toolbar.leadingAnchor.constraint(equalTo: tabBarController.tabBar.leadingAnchor).isActive = true
            toolbar.trailingAnchor.constraint(equalTo: tabBarController.tabBar.trailingAnchor).isActive = true
            toolbar.bottomAnchor.constraint(equalTo: tabBarController.tabBar.safeAreaLayoutGuide.bottomAnchor).isActive = true
            
            UIView.animate(withDuration: 0.3) {
                self.toolbar.alpha = 1.0
            }
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
    
    func configureToolbarButtons() {
        if explorerToolbarConfigurator == nil {
            explorerToolbarConfigurator = ExplorerToolbarConfigurator(
                downloadAction: downloadBarButtonPressed,
                shareLinkAction: shareLinkBarButtonPressed,
                moveAction: moveBarButtonPressed,
                copyAction: copyBarButtonPressed,
                deleteAction: deleteButtonPressed,
                moreAction: didPressedMoreBarButton
            )
        }
        
        toolbar.items = explorerToolbarConfigurator?.toolbarItems(forNodes: selectedNodes())
    }
    
    func configureFavouriteToolbarButtons() {
        if explorerToolbarConfigurator == nil {
            explorerToolbarConfigurator = FavouriteExplorerToolbarConfigurator(
                downloadAction: downloadBarButtonPressed,
                shareLinkAction: shareLinkBarButtonPressed,
                moveAction: moveBarButtonPressed,
                copyAction: copyBarButtonPressed,
                deleteAction: deleteButtonPressed,
                moreAction: didPressedMoreBarButton,
                favouriteAction: didPressedFavouriteBarButton
            )
        }
        
        toolbar.items = explorerToolbarConfigurator?.toolbarItems(forNodes: selectedNodes())
    }
    
    // MARK: - Toolbar Button actions
    private func didPressedFavouriteBarButton(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
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
    
    fileprivate func downloadBarButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        
        let transfers = selectedNodes.map { CancellableTransfer(handle: $0.handle, name: nil, appData: nil, priority: false, isFile: $0.isFile(), type: .download) }
        CancellableTransferRouter(presenter: self, transfers: transfers, transferType: .download).start()
        endEditingMode()
    }
    
    fileprivate func saveToPhotosButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        let saveMediaUseCase = SaveMediaToPhotosUseCase(downloadFileRepository: DownloadFileRepository(sdk: .shared), fileCacheRepository: FileCacheRepository.newRepo, nodeRepository: NodeRepository.newRepo, chatNodeRepository: ChatNodeRepository.newRepo, downloadChatRepository: DownloadChatRepository.newRepo)
        Task { @MainActor in
            do {
                try await saveMediaUseCase.saveToPhotos(nodes: selectedNodes.toNodeEntities())
            } catch {
                if let errorEntity = error as? SaveMediaToPhotosErrorEntity, errorEntity != .cancelled {
                    await SVProgressHUD.dismiss()
                    SVProgressHUD.show(
                        UIImage.saveToPhotos,
                        status: error.localizedDescription
                    )
                }
            }
            
            endEditingMode()
        }
    }
    
    fileprivate func shareLinkBarButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            GetLinkRouter(presenter: UIApplication.mnz_presentingViewController(),
                          nodes: selectedNodes).start()
            endEditingMode()
        }
    }
    
    fileprivate func deleteButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty,
              let rubbishBinNode = MEGASdk.shared.rubbishNode else {
            return
        }
        
        let moveRequestDelegate = MEGAMoveRequestDelegate(
            toMoveToTheRubbishBinWithFiles: UInt(selectedNodes.count),
            folders: 0) { [weak self] in
                self?.endEditingMode()
            }
        
        selectedNodes.forEach {
            MEGASdk.shared.move(
                $0,
                newParent: rubbishBinNode,
                delegate: moveRequestDelegate
            ) }
    }
    
    fileprivate func moveBarButtonPressed(_ button: UIBarButtonItem) {
        openBrowserViewController(withAction: .move)
    }
    
    fileprivate func copyBarButtonPressed(_ button: UIBarButtonItem) {
        openBrowserViewController(withAction: .copy)
    }
    
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
    
    fileprivate func didPressedMoreBarButton(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        
        let backupsUC = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let containsABackupNode = backupsUC.hasBackupNode(in: selectedNodes.toNodeEntities())
        let nodeActionsViewController = NodeActionViewController(nodes: selectedNodes, delegate: self, displayMode: displayMode, containsABackupNode: containsABackupNode, sender: button)
        nodeActionsViewController.accessoryActionDelegate = nodeAccessoryActionDelegate
        present(nodeActionsViewController, animated: true, completion: nil)
    }
    
    fileprivate func didPressedExportFile(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty else {
            return
        }
        
        let entityNodes = selectedNodes.toNodeEntities()
        ExportFileRouter(presenter: self, sender: button).export(nodes: entityNodes)
        endEditingMode()
    }
    
    fileprivate func didPressedSendToChat(_ button: UIBarButtonItem) {
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
    
    fileprivate func handleRemoveLinks(for nodes: [MEGANode]) {
        let router = ActionWarningViewRouter(presenter: self, nodes: nodes.toNodeEntities(), actionType: .removeLink, onActionStart: {
            SVProgressHUD.show()
        }, onActionFinish: { [weak self] result in
            self?.endEditingMode()
            switch result {
            case .success(let message):
                SVProgressHUD.showSuccess(withStatus: message)
            case .failure:
                SVProgressHUD.dismiss()
            }
        })
        router.start()
    }
    
    private func hide() {
        guard let nodes = selectedNodes()?.toNodeEntities() else {
            return
        }
        HideFilesAndFoldersRouter(presenter: self)
            .hideNodes(nodes)
        endEditingMode()
    }
    
    private func unhide() {
        guard let nodes = selectedNodes()?.toNodeEntities() else {
            return
        }
        HideFilesAndFoldersRouter(presenter: self)
            .unhideNodes(nodes)
        endEditingMode()
    }
    
    private func shareFolders() {
        guard let selected = selectedNodes()?.toNodeEntities() else { return }
        
        let sharedItemsRouter = SharedItemsViewRouter()
        let shareUseCase = ShareUseCase(
            shareRepository: ShareRepository.newRepo,
            filesSearchRepository: FilesSearchRepository.newRepo,
            nodeRepository: NodeRepository.newRepo)
        
        Task { @MainActor [shareUseCase] in
            do {
                _ = try await shareUseCase.createShareKeys(forNodes: selected)
                sharedItemsRouter.showShareFoldersContactView(withNodes: selected)
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
            endEditingMode()
        }
    }
    
    private func manageLinks() {
        guard let selected = selectedNodes() else { return }
        GetLinkRouter(
            presenter: self,
            nodes: selected
        ).start()
        endEditingMode()
    }
    
    private func addTo(mode: AddToMode) {
        guard let nodes = selectedNodes()?.toNodeEntities() else {
            return
        }
        AddToCollectionRouter(
            presenter: self,
            mode: mode,
            selectedPhotos: nodes).start()
    }
    
    // MARK: - Methods needs to be overriden by the subclass
    
    func selectedNodes() -> [MEGANode]? {
        fatalError("selectedNodes() method needs to be implemented by the subclass")
    }
    
    func endEditingMode() {
        fatalError("endEditingMode() method needs to be implemented by the subclass")
    }
}

extension ExplorerBaseViewController: TraitEnvironmentAware {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }
    
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        AppearanceManager.forceToolbarUpdate(toolbar)
    }
}

extension ExplorerBaseViewController: BrowserViewControllerDelegate {
    func nodeEditCompleted(_ complete: Bool) {
        endEditingMode()
    }
}

// MARK: - NodeActionViewControllerDelegate
extension ExplorerBaseViewController: NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) {
        handleNodesAction(action: action, nodes: nodes, sender: sender)
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        handleNodesAction(action: action, nodes: [node], sender: sender)
    }
    
    private func handleNodesAction(action: MegaNodeActionType, nodes: [MEGANode], sender: Any) {
        guard let sender = sender as? UIBarButtonItem else { return }
        switch action {
        case .download:
            downloadBarButtonPressed(sender)
        case .copy:
            copyBarButtonPressed(sender)
        case .move:
            moveBarButtonPressed(sender)
        case .shareLink:
            shareLinkBarButtonPressed(sender)
        case .moveToRubbishBin:
            deleteButtonPressed(sender)
        case .exportFile:
            didPressedExportFile(sender)
        case .sendToChat:
            didPressedSendToChat(sender)
        case .removeLink:
            handleRemoveLinks(for: nodes)
        case .saveToPhotos:
            saveToPhotosButtonPressed(sender)
        case .hide:
            DIContainer.tracker
                .trackAnalyticsEvent(with: HideNodeMultiSelectMenuItemEvent())
            hide()
        case .unhide:
            unhide()
        case .shareFolder:
            shareFolders()
        case .manageLink:
            manageLinks()
        case .addToAlbum:
            addTo(mode: .album)
        case .addTo:
            addTo(mode: .collection)
        default:
            break
        }
    }
}
