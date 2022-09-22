
extension ContactsViewController {
    @objc func shareFolderAction() {
        guard let nodes = nodesArray as? [MEGANode],
              selectedUsersArray.count > 0 else { return }
        
        if searchController.isActive {
            searchController.isActive = false
        }
        
        let inboxUseCase = InboxUseCase(repository: InboxRepository.newRepo)
        if inboxUseCase.containsAnyInboxNode(nodes.toNodeEntities) {
            shareNodes(withLevel: .accessRead)
        } else {
            selectPermissions(fromButton: shareFolderWithBarButtonItem)
        }
    }
    
    @objc func showBackupNodesWarningIfNeeded(completion: @escaping () -> Void) {
        BackupNodesValidator(presenter: self, inboxUseCase: InboxUseCase(repository: InboxRepository.newRepo), nodes: [node.toNodeEntity()]).showWarningAlertOrExecuteAction {
            completion()
        }
    }
}
