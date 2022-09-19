import Foundation
import MessageKit

final class NodeShareRouter: NSObject {

    private weak var viewController: UIViewController?

    init(viewController: UIViewController? = nil) {
        self.viewController = viewController
    }

    // MARK: -

    func exportFile(from node: MEGANode, sender: Any?) {
        guard let presenter = viewController else {
            return
        }
        ExportFileRouter(presenter: presenter, sender: sender).export(node: node.toNodeEntity())
    }

    func showSharingFolder(for node: MEGANode) {
        guard let viewController = viewController else { return }
        
        BackupNodesValidator(presenter: viewController, nodes: [node.toNodeEntity()]).showWarningAlertIfNeeded() {
            guard let navigation = UIStoryboard(name: "Contacts", bundle: nil)
                .instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as? UINavigationController
                else { return }
            let contactViewController = navigation.viewControllers.first as? ContactsViewController
            contactViewController?.nodesArray = [node]
            contactViewController?.contactsMode = .shareFoldersWith
            
            viewController.present(navigation, animated: true, completion: nil)
        }
    }

    func showManageSharing(for node: MEGANode) {
        guard let viewController = viewController else { return }
        
        BackupNodesValidator(presenter: viewController, nodes: [node.toNodeEntity()]).showWarningAlertIfNeeded() {
            guard let contactViewController = UIStoryboard(name: "Contacts", bundle: nil)
                .instantiateViewController(withIdentifier: "ContactsViewControllerID") as? ContactsViewController
                else { return }
            contactViewController.node = node
            contactViewController.contactsMode = .folderSharedWith
            
            viewController.present(contactViewController, animated: true, completion: nil)
        }
    }
}
