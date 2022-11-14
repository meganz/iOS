import MEGADomain

extension ContactsViewController {
    @objc func shareFolderAction() {
        guard let nodes = nodesArray as? [MEGANode],
              selectedUsersArray.count > 0 else { return }
        
        if searchController.isActive {
            searchController.isActive = false
        }
        
        Task {
            let myBackupsUseCase = MyBackupsUseCase(myBackupsRepository: MyBackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo, nodeValidationRepository: NodeValidationRepository.newRepo)
            
            if await myBackupsUseCase.containsABackupNode(nodes.toNodeEntities()) {
                shareNodes(withLevel: .accessRead)
            } else {
                selectPermissions(fromButton: shareFolderWithBarButtonItem)
            }
        }
    }
    
    @objc func showBackupNodesWarningIfNeeded(completion: @escaping () -> Void) {
        BackupNodesValidator(presenter: self, nodes: [node.toNodeEntity()]).showWarningAlertIfNeeded() {
            completion()
        }
    }
}
