
final class SharedItemsViewRouter: NSObject {
    
    func showShareFoldersContactView(withNodes nodes: [MEGANode]) {
        let presenter = UIApplication.mnz_visibleViewController()
        BackupNodesValidator(presenter: presenter, nodes: nodes.toNodeEntities()).showWarningAlertIfNeeded() {
            guard let contactsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsViewControllerID") as? ContactsViewController else {
                fatalError("Could not instantiate ContactsViewController")
            }
            contactsVC.contactsMode = .shareFoldersWith
            contactsVC.nodesArray = nodes
            let navigation = MEGANavigationController(rootViewController: contactsVC)
            presenter.present(navigation, animated: true, completion: nil)
        }
    }
    
}
