import ChatRepo
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAPhotos
import MEGAUIKit

class ExplorerBaseViewController: UIViewController {
    lazy var toolbar = UIToolbar()
    lazy var nodeAccessoryActionDelegate = DefaultNodeAccessoryActionDelegate()
    private var explorerToolbarConfigurator: ExplorerToolbarConfigurator?
    
    var isToolbarShown: Bool {
        return toolbar.superview != nil
    }
    
    var displayMode: DisplayMode { .unknown }

    var offlineActionGuard: any OfflineActionGuarding { OfflineActionGuard.neverBlocking }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        registerForAppearanceChanges()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isToolbarShown {
            endEditingMode()
        }
    }

    private func registerForAppearanceChanges() {
        registerForTraitChanges(UITraitCollection.systemTraitsAffectingColorAppearance) { (viewController: ExplorerBaseViewController, _: UITraitCollection) in
            AppearanceManager.forceToolbarUpdate(viewController.toolbar)
        }
    }

    /// - Returns: true when the action may run. Otherwise the standard no-connection prompt has
    /// already been shown and the caller must do nothing.
    func allowsActionRequiringConnection() -> Bool {
        offlineActionGuard.allowsActionRequiringConnection()
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
    
    // MARK: - Toolbar Button actions
    private func favourite(nodes: [MEGANode]) {
        let nodeEntities = nodes.toNodeEntities()
        let favouriteUseCase = NodeFavouriteActionUseCase(nodeFavouriteRepository: NodeFavouriteActionRepository.newRepo)
        // When every selected node is already favourited the action reads "Remove favourite", so
        // unfavourite all; otherwise favourite all of them.
        let shouldFavourite = !nodeEntities.allSatisfy { $0.isFavourite }
        Task {
            do {
                try await favouriteUseCase.favourite(nodes: nodeEntities, isFavourite: shouldFavourite)
            } catch {
                MEGALogError("[Favourite] Bulk favourite of \(nodeEntities.count) nodes failed: \(error)")
            }
        }
        endEditingMode()
    }
    
    fileprivate func downloadBarButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty,
              allowsActionRequiringConnection() else {
            return
        }
        
        let transfers = selectedNodes.map { CancellableTransfer(handle: $0.handle, name: $0.name, appData: nil, priority: false, isFile: $0.isFile(), type: .download) }
        CancellableTransferRouter(presenter: self, transfers: transfers, transferType: .download).start()
        endEditingMode()
    }
    
    fileprivate func saveToPhotosButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty,
              allowsActionRequiringConnection() else {
            return
        }
        SaveToPhotosCoordinator.SVProgressErrorOnly()
            .saveToPhotos(nodes: selectedNodes.toNodeEntities()) { [weak self] in
                self?.endEditingMode()
            }
    }
    
    fileprivate func shareLinkBarButtonPressed(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty,
              allowsActionRequiringConnection() else {
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
              allowsActionRequiringConnection(),
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
              allowsActionRequiringConnection(),
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
        let nodeActionsViewController = NodeActionViewController(nodes: selectedNodes, delegate: self, displayMode: displayMode, containsABackupNode: containsABackupNode, showsFavouriteAction: true, showsLabelAction: true, sender: button)
        nodeActionsViewController.accessoryActionDelegate = nodeAccessoryActionDelegate
        present(nodeActionsViewController, animated: true, completion: nil)
    }
    
    fileprivate func didPressedExportFile(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty,
              allowsActionRequiringConnection() else {
            return
        }
        
        let entityNodes = selectedNodes.toNodeEntities()
        ExportFileRouter(presenter: self, sender: button).export(nodes: entityNodes)
        endEditingMode()
    }
    
    fileprivate func didPressedSendToChat(_ button: UIBarButtonItem) {
        guard let selectedNodes = selectedNodes(),
              !selectedNodes.isEmpty,
              allowsActionRequiringConnection() else {
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
        guard !action.requiresConnection || allowsActionRequiringConnection() else { return }
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
        case .label:
            presentLabelActionSheet(for: nodes)
        case .favourite:
            favourite(nodes: nodes)
        default:
            break
        }
    }

    private func presentLabelActionSheet(for nodes: [MEGANode]) {
        let actionSheet = ActionSheetFactory().nodeLabelColorView(forNodes: nodes.map { $0.handle })
        present(actionSheet, animated: true)
        endEditingMode()
    }
}
