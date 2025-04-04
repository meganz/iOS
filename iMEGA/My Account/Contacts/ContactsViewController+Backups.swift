import MEGAAppSDKRepo
import MEGADomain

extension ContactsViewController {
    @objc func shareFolderAction() {
        guard let nodes = nodesArray as? [MEGANode],
              selectedUsersArray.count > 0 else { return }
        
        if searchController.isActive {
            searchController.isActive = false
        }
        
        let backupsUseCase = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        
        if backupsUseCase.hasBackupNode(in: nodes.toNodeEntities()) {
            shareNodes(withLevel: .accessRead)
        } else {
            selectPermissions(fromButton: shareFolderWithBarButtonItem)
        }
    }
    
    @objc func showBackupNodesWarningIfNeeded(completion: @escaping () -> Void) {
        BackupNodesValidator(presenter: self, nodes: [node.toNodeEntity()]).showWarningAlertIfNeeded {
            completion()
        }
    }
}
