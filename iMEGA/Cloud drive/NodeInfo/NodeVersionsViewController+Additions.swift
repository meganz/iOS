import MEGADomain

extension NodeVersionsViewController {
    @objc func setToolbarActionsEnabled(_ boolValue: Bool) {
        let selectedNodesArray = self.selectedNodesArray as? [MEGANode] ?? []
        let isBackupNode = MyBackupsUseCase(myBackupsRepository: MyBackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo).isBackupNode(node.toNodeEntity())
        let nodeAccessLevel = MEGASdk.shared.accessLevel(for: node).rawValue
        
        downloadBarButtonItem.isEnabled = selectedNodesArray.count == 1 && boolValue
        revertBarButtonItem.isEnabled = !isBackupNode && selectedNodesArray.count == 1 && selectedNodesArray.first?.handle != node.handle && nodeAccessLevel >= MEGAShareType.accessReadWrite.rawValue && boolValue
        removeBarButtonItem.isEnabled = nodeAccessLevel >= MEGAShareType.accessFull.rawValue && boolValue
    }
    
    @objc func configureToolbarItems() {
        let flexibleItem = UIBarButtonItem(systemItem: .flexibleSpace)
        let isBackupNode = MyBackupsUseCase(myBackupsRepository: MyBackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo).isBackupNode(node.toNodeEntity())
        
        setToolbarItems(isBackupNode ? [downloadBarButtonItem, flexibleItem, removeBarButtonItem] : [downloadBarButtonItem, flexibleItem, revertBarButtonItem, flexibleItem, removeBarButtonItem], animated: true)
    }
}
