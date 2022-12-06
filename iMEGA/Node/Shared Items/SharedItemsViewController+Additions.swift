import MEGADomain

extension SharedItemsViewController: ContatctsViewControllerDelegate {
    @objc func shareFolder() {
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            guard let nodes = selectedNodesMutableArray as? [MEGANode] else { return }
            BackupNodesValidator(presenter: self, nodes: nodes.toNodeEntities()).showWarningAlertIfNeeded() { [weak self] in
                guard let `self` = self,
                        let navigationController = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as? MEGANavigationController,
                        let contactsVC = navigationController.viewControllers.first as? ContactsViewController else {
                    return
                }
                
                contactsVC.contatctsViewControllerDelegate = self
                contactsVC.nodesArray = nodes
                contactsVC.contactsMode = .shareFoldersWith
                
                self.present(navigationController, animated: true)
            }
        }
    }
}

extension SharedItemsViewController {
    @objc func isFeatureFlagFingerprintVerificationEnabled() -> Bool {
        FeatureFlagProvider().isFeatureFlagEnabled(for: .mandatoryFingerprintVerification)
    }
}
