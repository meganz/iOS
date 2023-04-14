import MEGADomain

extension MyAccountHallViewController {
    @objc func checkIfBackupRootNodeExistsAndIsNotEmpty() {
        Task { [weak self] in
            guard let self else { return }
            let backupsUseCase = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
            
            self.backupsRootNode = try await backupsUseCase.backupsRootNode().toMEGANode(in: MEGASdkManager.sharedMEGASdk())
            
            if self.backupsRootNode != nil, await !backupsUseCase.isBackupsRootNodeEmpty() {
                self.isBackupSectionVisible = true
                self.tableView?.reloadData()
            }
        }
    }
    
    @objc func emptyStateView() -> UIView {
        EmptyStateView.create(for: .backups(searchActive: navigationItem.searchController?.isActive ?? false))
    }
    
    @objc func navigateToBackups() {
        guard let cloudDriveVC = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(identifier: "CloudDriveID") as? CloudDriveViewController else { return }
        if let backupsRootNode {
            cloudDriveVC.parentNode = backupsRootNode
        }
        cloudDriveVC.displayMode = .backup
        navigationController?.pushViewController(cloudDriveVC, animated: true)
    }
}
