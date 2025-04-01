import ChatRepo
import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAPhotos
import MEGASDKRepo

class NodeActionViewControllerGenericDelegate: NodeActionViewControllerDelegate {
    private weak var viewController: UIViewController?
    private(set) var isNodeFromFolderLink: Bool
    private(set) var messageId: HandleEntity?
    private(set) var chatId: HandleEntity?
    private let moveToRubbishBinViewModel: any MoveToRubbishBinViewModelProtocol
    private let nodeActionListener: (MegaNodeActionType?) -> Void
    
    private let saveMediaToPhotosUseCase = SaveMediaToPhotosUseCase(
        downloadFileRepository: DownloadFileRepository(
            sdk: MEGASdk.shared
        ),
        fileCacheRepository: FileCacheRepository.newRepo,
        nodeRepository: NodeRepository.newRepo, 
        chatNodeRepository: ChatNodeRepository.newRepo,
        downloadChatRepository: DownloadChatRepository.newRepo
    )

    init(
        viewController: UIViewController,
        isNodeFromFolderLink: Bool = false,
        messageId: HandleEntity? = nil,
        chatId: HandleEntity? = nil,
        moveToRubbishBinViewModel: any MoveToRubbishBinViewModelProtocol,
        nodeActionListener: @escaping (MegaNodeActionType?) -> Void = { _ in }
    ) {
        self.viewController = viewController
        self.isNodeFromFolderLink = isNodeFromFolderLink
        self.messageId = messageId
        self.chatId = chatId
        self.moveToRubbishBinViewModel = moveToRubbishBinViewModel
        self.nodeActionListener = nodeActionListener
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) {
        nodeActionListener(action)
        guard let viewController = viewController else { return }
        
        switch action {
        case .copy, .move:
            showBrowserViewController(nodes: nodes, action: (action == .copy) ? .copy : .move)
        case .exportFile:
            exportFile(nodes: nodes, sender: sender)
        case .shareLink, .manageLink:
            showLink(for: nodes)
        case .removeLink:
            removeLink(for: nodes, in: viewController)
        case .sendToChat:
            handleSendToChat(for: nodes, from: viewController)
        case .moveToRubbishBin:
            moveToRubbishBinViewModel.moveToRubbishBin(nodes: nodes.toNodeEntities())
        case .download:
            handleDownloadAction(for: nodes.toNodeEntities())
        case .saveToPhotos:
            saveToPhotos(nodes)
        case .hide:
            hide(nodes: nodes.toNodeEntities())
        case .unhide:
            unhide(nodes: nodes.toNodeEntities())
        case .addToAlbum:
            addTo(mode: .album, nodes: nodes.toNodeEntities())
        case .addTo:
            addTo(mode: .collection, nodes: nodes.toNodeEntities())
        default:
            break
        }
    }
    
    private func handleSendToChat(for nodes: [MEGANode], from viewController: UIViewController) {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        guard
            let navigationController = storyboard.instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController,
            let sendToViewController = navigationController.viewControllers.first as? SendToViewController
        else {
            return
        }
        
        sendToViewController.nodes = nodes
        sendToViewController.sendMode = .cloud
        viewController.present(navigationController, animated: true)
    }
    
    func nodeAction(
        _ nodeAction: NodeActionViewController,
        didSelect action: MegaNodeActionType,
        for node: MEGANode,
        from sender: Any
    ) {
        nodeActionListener(action)
        guard let viewController = viewController else { return }
        switch action {
        case .editTextFile:
            showEditTextFile(for: node)
            
        case .download:
            download(node, isNodeFromFolderLink: isNodeFromFolderLink, messageId: messageId, chatId: chatId)
        
        case .copy, .move:
            showBrowserViewController(nodes: [node], action: (action == .copy) ? .copy : .move)

        case .rename:
            node.mnz_renameNode(in: viewController)
            
        case .exportFile:
            exportFile(nodes: [node], sender: sender)

        case .shareFolder:
            openShareFolderDialog(node, viewController: viewController)
            
        case .manageShare:
            BackupNodesValidator(presenter: viewController, nodes: [node.toNodeEntity()]).showWarningAlertIfNeeded { [weak self] in
                self?.manageShare(node)
            }
            
        case .info:
            showNodeInfo(node)
            
        case .viewVersions:
            node.mnz_showVersions(in: viewController)

        case .leaveSharing:
            node.mnz_leaveSharing(in: viewController)

        case .shareLink, .manageLink:
            showLink(for: [node])
            
        case .removeLink:
            removeLink(for: [node], in: viewController)
            
        case .moveToRubbishBin:
            moveToRubbishBinViewModel.moveToRubbishBin(nodes: [node].toNodeEntities())
            
        case .remove:
            remove(node, in: viewController)
            
        case .removeSharing:
            node.mnz_removeSharing()
            
        case .sendToChat:
            node.mnz_sendToChat(in: viewController)
            
        case .saveToPhotos:
            saveToPhotos([node])
            
        case .favourite:
            favourite(node)
            
        case .label:
            node.mnz_labelActionSheet(in: viewController)
        
        case .restore:
            node.mnz_restore()
            
        case .import:
            node.openBrowserToImport(in: viewController)
        
        case .hide:
            hide(nodes: [node.toNodeEntity()])
            
        case .unhide:
            unhide(nodes: [node.toNodeEntity()])
        
        case .addToAlbum:
            addTo(mode: .album, nodes: [node.toNodeEntity()])
        
        case .addTo:
            addTo(mode: .collection, nodes: [node.toNodeEntity()])
        default:
            break
        }
    }
    
    private func removeLink(for nodes: [MEGANode], in viewController: UIViewController) {
        let router = ActionWarningViewRouter(presenter: viewController, nodes: nodes.toNodeEntities(), actionType: .removeLink, onActionStart: {
            SVProgressHUD.show()
        }, onActionFinish: {
            switch $0 {
            case .success(let message):
                SVProgressHUD.showSuccess(withStatus: message)
            case .failure:
                SVProgressHUD.dismiss()
            }
        })
        router.start()
    }
    
    private func remove(_ node: MEGANode, in viewController: UIViewController) {
        node.mnz_remove(in: viewController) { shouldRemove in
            if shouldRemove {
                guard node.mnz_isPlaying() else { return }
                AudioPlayerManager.shared.closePlayer()
            }
        }
    }
    
    private func showLink(for nodes: [MEGANode]) {
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            GetLinkRouter(presenter: UIApplication.mnz_presentingViewController(),
                          nodes: nodes).start()
        }
    }
    
    private func showEditTextFile(for node: MEGANode) {
        if let vc = (viewController as? MEGANavigationController)?.viewControllers.last {
            node.mnz_editTextFile(in: vc)
        }
    }

    private func showNodeInfo(_ node: MEGANode) {
        let nodeInfoController = NodeInfoViewController.makeInstance(
            with: NodeInfoViewModel(
                withNode: node,
                nodeUseCase: NodeUseCase(
                    nodeDataRepository: NodeDataRepository.newRepo,
                    nodeValidationRepository: NodeValidationRepository.newRepo,
                    nodeRepository: NodeRepository.newRepo),
                backupUseCase: BackupsUseCase(
                    backupsRepository: BackupsRepository.newRepo,
                    nodeRepository: NodeRepository.newRepo
                )
            ),
            delegate: nil
        )

        nodeInfoController.nodeInfoViewController.display(node, withDelegate: self)
        viewController?.present(nodeInfoController.navigationController, animated: true, completion: nil)
    }
    
    private func showNodeVersions(_ node: MEGANode) {
        guard let viewController = viewController else {
            return
        }
        node.mnz_showVersions(in: viewController)
    }
    
    private func showBrowserViewController(nodes: [MEGANode], action: BrowserAction) {
        if let navigationController = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController {
            viewController?.present(navigationController, animated: true, completion: nil)

            if let browserViewController = navigationController.viewControllers.first as? BrowserViewController {
                browserViewController.selectedNodesArray = nodes
                browserViewController.browserAction = action
            }
        }
    }
    
    private func saveToPhotos(_ nodes: [MEGANode]) {
        let wrapper = SaveMediaToPhotosUseCaseOCWrapper()
        wrapper.saveToPhotos(nodes: nodes)
    }
    
    private func download(_ node: MEGANode, isNodeFromFolderLink: Bool, messageId: HandleEntity? = nil, chatId: HandleEntity? = nil) {
        guard let viewController = viewController else {
            return
        }
        
        let transferFactory = CancellableTransfer.Factory(
            node: node,
            isNodeFromFolderLink: isNodeFromFolderLink,
            messageId: messageId,
            chatId: chatId
        )
        let transfer = transferFactory.make()
        
        let routerFactory = CancellableTransferRouter.Factory(
            presenter: viewController,
            node: node,
            transfers: [transfer],
            isNodeFromFolderLink: isNodeFromFolderLink,
            messageId: messageId,
            chatId: chatId
        )
        let router = routerFactory.make()
        router.start()
    }
    
    private func handleDownloadAction(for nodes: [NodeEntity]) {
        guard let viewController = viewController else {
            return
        }
        
        let transfers = nodes.map { CancellableTransfer(handle: $0.handle, name: nil, appData: nil, priority: false, isFile: $0.isFile, type: .download) }
        CancellableTransferRouter(
            presenter: viewController,
            transfers: transfers,
            transferType: .download
        )
        .start()
    }
    
    private func openShareFolderDialog(_ node: MEGANode, viewController: UIViewController) {
        Task { @MainActor in
            do {
                let shareUseCase = ShareUseCase(
                    shareRepository: ShareRepository.newRepo,
                    filesSearchRepository: FilesSearchRepository.newRepo,
                    nodeRepository: NodeRepository.newRepo)
                _ = try await shareUseCase.createShareKeys(forNodes: [node.toNodeEntity()])
                NodeShareRouter(viewController: viewController)
                    .showSharingFolder(for: node)
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
    
    private func manageShare(_ node: MEGANode) {
        let contactsStoryboard = UIStoryboard(name: "Contacts", bundle: nil)
        guard let contactsViewController = contactsStoryboard.instantiateViewController(withIdentifier: "ContactsViewControllerID") as? ContactsViewController else { return }
        contactsViewController.node = node
        contactsViewController.contactsMode = .folderSharedWith
        
        if let navigationController = viewController as? UINavigationController {
            navigationController.pushViewController(contactsViewController, animated: true)
        } else {
            viewController?.present(contactsViewController, animated: true)
        }
    }
    
    private func favourite(_ node: MEGANode) {
        let nodefavouriteActionUseCase =  NodeFavouriteActionUseCase(nodeFavouriteRepository: NodeFavouriteActionRepository.newRepo)
        if node.isFavourite {
            Task {
                try await nodefavouriteActionUseCase.unFavourite(node: node.toNodeEntity())
            }
        } else {
            Task {
                try await nodefavouriteActionUseCase.favourite(node: node.toNodeEntity())
            }
        }
    }
    
    private func exportFile(nodes: [MEGANode], sender: Any) {
        guard let viewController = viewController else { return }
        Task {
            ExportFileRouter(presenter: viewController, sender: sender).export(nodes: nodes.toNodeEntities())
        }
    }
    
    private func hide(nodes: [NodeEntity]) {
        guard let viewController = viewController else { return }
        Task {
            HideFilesAndFoldersRouter(presenter: viewController).hideNodes(nodes)
        }
    }
    
    private func unhide(nodes: [NodeEntity]) {
        guard let viewController else { return }
        
        HideFilesAndFoldersRouter(presenter: viewController)
            .unhideNodes(nodes)
    }
    
    private func addTo(mode: AddToMode, nodes: [NodeEntity]) {
        guard let viewController = viewController else { return }
        
        AddToCollectionRouter(
            presenter: viewController,
            mode: mode,
            selectedPhotos: nodes).start()
    }
}

// MARK: - NodeInfoViewControllerDelegate

extension NodeActionViewControllerGenericDelegate: NodeInfoViewControllerDelegate {

    func nodeInfoViewController(
        _ nodeInfoViewController: NodeInfoViewController,
        presentParentNode node: MEGANode) {
        node.navigateToParentAndPresent()
    }
}
