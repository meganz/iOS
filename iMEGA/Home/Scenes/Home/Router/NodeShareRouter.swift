import Foundation

final class NodeShareRouter: NSObject {

    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController? = nil) {
        self.navigationController = navigationController
    }

    // MARK: -

    func showSharing(for node: MEGANode, sender: Any?) {
        let activityViewController = UIActivityViewController(forNodes: [node], sender: sender)
        navigationController?.present(activityViewController, animated: true, completion: nil)
    }

    func showSharingFolder(for node: MEGANode) {
        guard let navigation = UIStoryboard(name: "Contacts", bundle: nil)
            .instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as? UINavigationController
            else { return }
        let contactViewController = navigation.viewControllers.first as? ContactsViewController
        contactViewController?.nodesArray = [node]
        contactViewController?.contactsMode = .shareFoldersWith
        navigationController?.present(navigation, animated: true, completion: nil)
    }

    func showManageSharing(for node: MEGANode) {
        guard let contactViewController = UIStoryboard(name: "Contacts", bundle: nil)
            .instantiateViewController(withIdentifier: "ContactsViewControllerID") as? ContactsViewController
            else { return }
        contactViewController.node = node
        contactViewController.contactsMode = .folderSharedWith
        navigationController?.present(contactViewController, animated: true, completion: nil)
    }
}
