import Foundation

final class NodeActionViewControllerGenericDelegate:
    NodeActionViewControllerDelegate
{
    private weak var viewController: UINavigationController?

    init(viewController: UINavigationController) {
        self.viewController = viewController
    }

    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        guard let viewController = viewController else { return }
        switch action {
        case .download:
            if let progressImage = UIImage(named: "hudDownload") {
                SVProgressHUD.show(
                    progressImage,
                    status: NSLocalizedString("downloadStarted", comment: "Message shown when a download starts")
                )
            }
            node.mnz_downloadNode()
        case .copy, .move:
            showBrowserViewController(node: node, action: (action == .copy) ? .copy : .move)

        case .rename:
            node.mnz_renameNode(in: viewController)
        case .share:
            let activityViewController = UIActivityViewController(forNodes: [node], sender: sender)
            viewController.present(activityViewController, animated: true, completion: nil)

        case .manageShare:
            let contactsStoryboard = UIStoryboard(name: "Contacts", bundle: nil)
            guard let contactsViewController = contactsStoryboard.instantiateViewController(withIdentifier: "ContactsViewControllerID") as? ContactsViewController else { return }
            contactsViewController.node = node
            contactsViewController.contactsMode = .shareFoldersWith
            viewController.pushViewController(contactsViewController, animated: true)

        case .info:
            showNodeInfo(node)

        case .leaveSharing:
            node.mnz_leaveSharing(in: viewController)

        case .getLink, .manageLink:
            if MEGAReachabilityManager.isReachableHUDIfNot() {
                CopyrightWarningViewController.presentGetLinkViewController(
                    for: [node],
                    in: UIApplication.mnz_presentingViewController()
                )
            }
        case .removeLink:
            node.mnz_removeLink()
        case .moveToRubbishBin:
            node.mnz_moveToTheRubbishBin { }
        case .remove:
            node.mnz_remove(in: viewController)
        case .removeSharing:
            node.mnz_removeSharing()
        case .sendToChat:
            node.mnz_sendToChat(in: viewController)
        case .saveToPhotos:
            node.mnz_saveToPhotos(withApi: MEGASdkManager.sharedMEGASdk())
        case .favourite:
            MEGASdkManager.sharedMEGASdk().setNodeFavourite(node, favourite:!node.isFavourite)
        case .label:
            node.mnz_labelActionSheet(in: viewController)
        default:
            break
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

    private func showBrowserViewController(node: MEGANode, action: BrowserAction) {
        if let navigationController = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController {
            viewController?.present(navigationController, animated: true, completion: nil)

            if let browserViewController = navigationController.viewControllers.first as? BrowserViewController {
                browserViewController.selectedNodesArray = [node]
                browserViewController.browserAction = action
            }
        }
    }
}

// MARK: - NodeInfoViewControllerDelegate

extension NodeActionViewControllerGenericDelegate: NodeInfoViewControllerDelegate {

    func nodeInfoViewController(
        _ nodeInfoViewController: NodeInfoViewController,
        presentParentNode node: MEGANode) {

    }
}
