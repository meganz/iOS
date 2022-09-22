import MEGADomain

extension MyAccountHallViewController {
    func fetchInboxNode() -> NodeEntity? {
        AccountUseCase(repository: AccountRepository(sdk: MEGASdkManager.sharedMEGASdk())).inboxNode()
    }
    
    @objc func checkIfBackupRootNodeExistsAndIsNotEmpty() {
        Task {
            let existBackupAndIsNotEmpty = await withTaskGroup(of: Bool.self) { group -> Bool in
                group.addTask {
                    do {
                        let existsBackupNode = try await AccountUseCase(repository: AccountRepository(sdk: MEGASdkManager.sharedMEGASdk())).existsBackupNode()
                        return existsBackupNode
                    } catch {
                        return false
                    }
                }
                
                group.addTask {
                    await !InboxUseCase(inboxRepository: InboxRepository.newRepo, nodeRepository: NodeRepository.newRepo).isBackupRootNodeEmpty()
                }
                
                return await group.allSatisfy { $0 == true }
            }
        
            if existBackupAndIsNotEmpty {
                isBackupSectionVisible = true
                tableView.reloadData()
            }
        }
    }
    
    @objc func emptyStateView() -> UIView {
        EmptyStateView.create(for: .backups(searchActive: navigationItem.searchController?.isActive ?? false))
    }
    
    @objc func navigateToBackups() {
        guard let cloudDriveVC = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(identifier: "CloudDriveID") as? CloudDriveViewController else { return }
        if let inboxNode = fetchInboxNode() {
            cloudDriveVC.parentNode = inboxNode.toMEGANode(in: MEGASdkManager.sharedMEGASdk())
        }
        cloudDriveVC.displayMode = .backup
        navigationController?.pushViewController(cloudDriveVC, animated: true)
    }
}
