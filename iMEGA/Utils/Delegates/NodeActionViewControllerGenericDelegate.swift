import Foundation

final class NodeActionViewControllerGenericDelegate:
    NodeActionViewControllerDelegate
{
    private weak var viewController: UIViewController?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        guard let viewController = viewController else { return }
        switch action {
        case .editTextFile:
            showEditTextFile(for: node)
            
        case .download:
            download(node)
        
        case .copy, .move:
            showBrowserViewController(node: node, action: (action == .copy) ? .copy : .move)

        case .rename:
            node.mnz_renameNode(in: viewController)
            
        case .exportFile:
            exportFile(node: node, sender: sender)

        case .shareFolder:
            shareFolder(node)
            
        case .manageShare:
            manageShare(node)
            
        case .info:
            showNodeInfo(node)
            
        case .viewVersions:
            node.mnz_showVersions(in: viewController)

        case .leaveSharing:
            node.mnz_leaveSharing(in: viewController)

        case .shareLink, .manageLink:
            showLink(for: node)
            
        case .removeLink:
            node.mnz_removeLink()
            
        case .moveToRubbishBin:
            node.mnz_moveToTheRubbishBin { }
            
        case .remove:
            remove(node, in: viewController)
            
        case .removeSharing:
            node.mnz_removeSharing()
            
        case .sendToChat:
            node.mnz_sendToChat(in: viewController)
            
        case .saveToPhotos:
            node.mnz_saveToPhotos()
            
        case .favourite:
            favourite(node)
            
        case .label:
            node.mnz_labelActionSheet(in: viewController)
        
        case .restore:
            node.mnz_restore()
            
        case .import:
            node.openBrowserToImport(in: viewController)
            
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
            CopyrightWarningViewController.presentGetLinkViewController(
                for: [node],
                   in: UIApplication.mnz_presentingViewController()
            )
        }
    }
    
    private func showEditTextFile(for node: MEGANode) {
        if let vc = (viewController as? MEGANavigationController)?.viewControllers.last {
            node.mnz_editTextFile(in: vc)
        }
    }

    private func showNodeInfo(_ node: MEGANode) {
        guard let nodeInfoNavigationController = UIStoryboard(name: "Node", bundle: nil).instantiateViewController(withIdentifier: "NodeInfoNavigationControllerID") as? UINavigationController,
            let nodeInfoVC = nodeInfoNavigationController.viewControllers.first as? NodeInfoViewController else {
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
    
    private func download(_ node: MEGANode) {
        SVProgressHUD.show(
            Asset.Images.Hud.hudDownload.image,
            status: Strings.Localizable.downloadStarted
        )
        node.mnz_downloadNode()
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
        let nodefavouriteActionUseCase =  NodeFavouriteActionUseCase(nodeFavouriteRepository: NodeFavouriteActionRepository(sdk: MEGASdkManager.sharedMEGASdk()))
        if node.isFavourite {
            nodefavouriteActionUseCase.removeNodeFromFavourite(nodeHandle: node.handle) { (result) in
                switch result {
                case .success():
                    if #available(iOS 14.0, *) {
                        QuickAccessWidgetManager().deleteFavouriteItem(for: node)
                    }
                case .failure(_):
                    break
                }
            }
        } else {
            nodefavouriteActionUseCase.addNodeToFavourite(nodeHandle: node.handle) { (result) in
                switch result {
                case .success():
                    if #available(iOS 14.0, *) {
                        QuickAccessWidgetManager().insertFavouriteItem(for: node)
                    }
                case .failure(_):
                    break
                }
            }
        }
    }
    
    private func exportFile(node: MEGANode, sender: Any) {
        guard let viewController = viewController else { return }
        ExportFileRouter(presenter: viewController, sender: sender).export(node: NodeEntity(node: node))
    }
}

// MARK: - NodeInfoViewControllerDelegate

extension NodeActionViewControllerGenericDelegate: NodeInfoViewControllerDelegate {

    func nodeInfoViewController(
        _ nodeInfoViewController: NodeInfoViewController,
        presentParentNode node: MEGANode) {

    }
}
