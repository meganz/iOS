import ChatRepo
import Foundation
import MEGADomain
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
            showBrowserViewController(node: node, action: (action == .copy) ? .copy : .move)

        case .rename:
            node.mnz_renameNode(in: viewController)
            
        case .exportFile:
            exportFile(node: node, sender: sender)

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
            showLink(for: node)
            
        case .removeLink:
            let router = ActionWarningViewRouter(presenter: viewController, nodes: [node.toNodeEntity()], actionType: .removeLink, onActionStart: {
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
            
        case .moveToRubbishBin:
            moveToRubbishBinViewModel.moveToRubbishBin(nodes: [node].toNodeEntities())
            
        case .remove:
            remove(node, in: viewController)
            
        case .removeSharing:
            node.mnz_removeSharing()
            
        case .sendToChat:
            node.mnz_sendToChat(in: viewController)
            
        case .saveToPhotos:
            saveToPhotos(node)
            
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
        default:
            break
        }
    }
    
    private func remove(_ node: MEGANode, in viewController: UIViewController) {
        node.mnz_remove(in: viewController) { shouldRemove in
            if shouldRemove {
                guard node.mnz_isPlaying() else { return }
                AudioPlayerManager.shared.closePlayer()
            }
        }
    }
    
    private func showLink(for node: MEGANode) {
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            GetLinkRouter(presenter: UIApplication.mnz_presentingViewController(),
                          nodes: [node]).start()
        }
    }
    
    private func showEditTextFile(for node: MEGANode) {
        if let vc = (viewController as? MEGANavigationController)?.viewControllers.last {
            node.mnz_editTextFile(in: vc)
        }
    }

    private func showNodeInfo(_ node: MEGANode) {
        let nodeInfoNavigationController = NodeInfoViewController.instantiate(
            withViewModel: .init(withNode: node),
            delegate: nil
        )
        
        guard let nodeInfoVC = nodeInfoNavigationController.viewControllers.first as? NodeInfoViewController else {
            return
        }
        nodeInfoVC.display(node, withDelegate: self)
        viewController?.present(nodeInfoNavigationController, animated: true, completion: nil)
    }
    
    private func showNodeVersions(_ node: MEGANode) {
        guard let viewController = viewController else {
            return
        }
        node.mnz_showVersions(in: viewController)
    }
    
    private func showBrowserViewController(node: MEGANode, action: BrowserAction) {
        if let navigationController = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController {
            viewController?.present(navigationController, animated: true, completion: nil)

            if let browserViewController = navigationController.viewControllers.first as? BrowserViewController {
                browserViewController.selectedNodesArray = [node]
                browserViewController.browserAction = action
            }
        }
    }
    
    private func saveToPhotos(_ node: MEGANode) {
        let wrapper = SaveMediaToPhotosUseCaseOCWrapper()
        wrapper.saveToPhotos(node: node)
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
    
    private func openShareFolderDialog(_ node: MEGANode, viewController: UIViewController) {
        Task { @MainActor in
            do {
                let shareUseCase = ShareUseCase(repo: ShareRepository.newRepo)
                _ = try await shareUseCase.createShareKeys(forNodes: [node.toNodeEntity()])
                showContactListForShareFolderNode(node, viewController: viewController)
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
    
    private func showContactListForShareFolderNode(_ node: MEGANode, viewController: UIViewController) {
        BackupNodesValidator(presenter: viewController, nodes: [node.toNodeEntity()]).showWarningAlertIfNeeded { [weak self] in
            self?.shareFolder(node)
       }
    }
    
    private func shareFolder(_ node: MEGANode) {
        let contactsStoryboard = UIStoryboard(name: "Contacts", bundle: nil)
        guard let navigationController = contactsStoryboard.instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as? MEGANavigationController else { return }
        let contactsViewController = navigationController.viewControllers.first as! ContactsViewController
        contactsViewController.nodesArray = [node]
        contactsViewController.contactsMode = .shareFoldersWith
        
        viewController?.present(navigationController, animated: true)
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
    
    private func exportFile(node: MEGANode, sender: Any) {
        guard let viewController = viewController else { return }
        ExportFileRouter(presenter: viewController, sender: sender).export(node: node.toNodeEntity())
    }
    
    private func hide(nodes: [NodeEntity]) {
        let nodeActionUseCase = NodeActionUseCase(repo: NodeActionRepository.newRepo)
        Task {
            _ = await nodeActionUseCase.hide(nodes: nodes)
        }
    }
    
    private func unhide(nodes: [NodeEntity]) {
        let nodeActionUseCase = NodeActionUseCase(repo: NodeActionRepository.newRepo)
        Task {
            _ = await nodeActionUseCase.unhide(nodes: nodes)
        }
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
