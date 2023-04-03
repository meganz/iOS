import MEGADomain

extension MyAccountHallViewController {
    @objc func checkIfBackupRootNodeExistsAndIsNotEmpty() {
        Task { [weak self] in
            guard let self else { return }
            let myBackupsUseCase = MyBackupsUseCase(myBackupsRepository: MyBackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
            
            self.myBackupsNode = try await myBackupsUseCase.myBackupsRootNode().toMEGANode(in: MEGASdkManager.sharedMEGASdk())
            
            if self.myBackupsNode != nil, await !myBackupsUseCase.isMyBackupsRootNodeEmpty() {
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
        if let myBackupsNode {
            cloudDriveVC.parentNode = myBackupsNode
        }
        cloudDriveVC.displayMode = .backup
        navigationController?.pushViewController(cloudDriveVC, animated: true)
    }
}
