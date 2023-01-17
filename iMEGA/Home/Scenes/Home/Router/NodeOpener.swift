import MEGADomain

final class NodeOpener {

    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    func openNode(_ nodeHandle: HandleEntity) {
        guard let node = MEGASdkManager.sharedMEGASdk().node(forHandle: nodeHandle) else { return }
        switch node.isFolder() {
        case true: openFolderNode(node)
        case false: openFileNode(node, allNodes: nil)
        }
    }
    
    func openNode(_ node: MEGANode, allNodes: [MEGANode]?) {
        switch node.isFolder() {
        case true: openFolderNode(node)
        case false: openFileNode(node, allNodes: allNodes)
        }
    }
    
    func openNodeActions(_ nodeHandle: HandleEntity, sender: Any) {
        guard let navigationController = navigationController else { return }
        guard let node = MEGASdkManager.sharedMEGASdk().node(forHandle: nodeHandle) else { return }
        
        Task {
            let myBackupsUC = MyBackupsUseCase(myBackupsRepository: MyBackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
            let isBackupNode = await myBackupsUC.isBackupNode(node.toNodeEntity())
            let delegate = NodeActionViewControllerGenericDelegate(viewController: navigationController)
            let nodeActionVC = await NodeActionViewController(node: node,
                                                        delegate: delegate,
                                                        displayMode: .cloudDrive,
                                                        isIncoming: false,
                                                        isBackupNode: isBackupNode,
                                                        sender: sender)
            await navigationController.present(nodeActionVC, animated: true, completion: nil)
        }
    }
    
    //MARK: - Private
    
    private func openFileNode(_ node: MEGANode, allNodes: [MEGANode]?) {
        guard (node.name as NSString?)?.mnz_isVisualMediaPathExtension == true else {
            node.mnz_open(in: navigationController, folderLink: false, fileLink: nil)
            return
        }
        
        let nodes = allNodes ?? [node]
        let index = nodes.firstIndex(where: { $0.handle == node.handle }) ?? 0
        let mediaNodes = NSMutableArray(array: nodes)
        let photoBrowserForMediaNode = MEGAPhotoBrowserViewController.photoBrowser(
            withMediaNodes: mediaNodes,
            api: MEGASdkManager.sharedMEGASdk(),
            displayMode: .cloudDrive,
            preferredIndex: UInt(truncatingIfNeeded: index)
        )
        navigationController?.present(photoBrowserForMediaNode, animated: true, completion: nil)
    }

    private func openFolderNode(_ node: MEGANode) {
        let cloudStoryboard = UIStoryboard(name: "Cloud", bundle: nil)
        guard let cloudDriveViewController =
            cloudStoryboard.instantiateViewController(withIdentifier: "CloudDriveID") as? CloudDriveViewController
        else { return }
        cloudDriveViewController.parentNode = node
        navigationController?.pushViewController(cloudDriveViewController, animated: true)
    }
}
