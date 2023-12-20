import MEGADomain
import MEGASDKRepo

extension MyAccountHallViewController {
    @objc func checkIfBackupRootNodeExistsAndIsNotEmpty() {
        Task { [weak self] in
            guard let self else { return }
            let backupsUseCase = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
            
            self.backupsRootNode = try await backupsUseCase.backupsRootNode().toMEGANode(in: MEGASdk.sharedSdk)
            
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
        guard
            let navigationController,
            let backupsRootNode
        else { return }
        
        let factory = CloudDriveViewControllerFactory.make(nc: navigationController)
        let cloudDriveVC = factory.buildBare(
            parentNode: backupsRootNode.toNodeEntity(),
            options: .init(displayMode: .backup)
        )
        
        if let cloudDriveVC {
            navigationController.pushViewController(cloudDriveVC, animated: true)
        }
    }
}
