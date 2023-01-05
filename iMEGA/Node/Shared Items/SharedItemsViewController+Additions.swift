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
    
    @objc func incomingSharedFolderName(node: MEGANode) -> String? {
        guard isFeatureFlagFingerprintVerificationEnabled() else {
            return node.name
        }
        return Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName
    }
    
    @objc func incomingSharedFolderPermissionIcon(type: MEGAShareType) -> UIImage? {
        guard isFeatureFlagFingerprintVerificationEnabled() else {
            return UIImage.mnz_permissionsButtonImage(for: type)
        }
        return Asset.Images.SharedItems.warningPermission.image
    }
    
    @objc func configOutgoingVerifyCredentialCellIfNeeded(_ cell: SharedItemsTableViewCell) {
        guard isFeatureFlagFingerprintVerificationEnabled() else {
            cell.nameLabel.textColor = UIColor.mnz_label()
            cell.permissionsButton.isHidden = true
            return
        }
        cell.nameLabel.textColor = UIColor.mnz_red(for: self.traitCollection)
        cell.permissionsButton.setImage(Asset.Images.SharedItems.warningPermission.image, for: .normal)
        cell.permissionsButton.isHidden = false
    }
}
