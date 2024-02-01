import MEGADomain

final class SharedItemsViewRouter: NSObject {
    
    func showShareFoldersContactView(withNodes nodes: [NodeEntity]) {
        let megaNodes = nodes.compactMap {
            MEGASdk.shared.node(forHandle: $0.handle)
        }
        showShareFoldersContactView(withNodes: megaNodes)
    }
    
    func showShareFoldersContactView(withNodes nodes: [MEGANode]) {
        let presenter = UIApplication.mnz_visibleViewController()
        BackupNodesValidator(presenter: presenter, nodes: nodes.toNodeEntities()).showWarningAlertIfNeeded {
            guard let contactsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsViewControllerID") as? ContactsViewController else {
                fatalError("Could not instantiate ContactsViewController")
            }
            contactsVC.contactsMode = .shareFoldersWith
            contactsVC.nodesArray = nodes
            let navigation = MEGANavigationController(rootViewController: contactsVC)
            presenter.present(navigation, animated: true, completion: nil)
        }
    }
    
    @objc func showPendingOutShareModal(for email: String) {
        CustomModalAlertRouter(.pendingUnverifiedOutShare,
                               presenter: UIApplication.mnz_presentingViewController(),
                               outShareEmail: email).start()
    }
    
}
