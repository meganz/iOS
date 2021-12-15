final class NodeOpener {

    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    func openNode(_ nodeHandle: MEGAHandle) {
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
    
    func openNodeActions(_ nodeHandle: MEGAHandle, sender: Any) {
        guard let navigationController = navigationController else { return }
        guard let node = MEGASdkManager.sharedMEGASdk().node(forHandle: nodeHandle) else { return }
        
        let delegate = NodeActionViewControllerGenericDelegate(viewController: navigationController)
        let nodeActionVC = NodeActionViewController(node: node,
                                                    delegate: delegate,
                                                    displayMode: .cloudDrive,
                                                    isIncoming: false,
                                                    sender: sender)
        navigationController.present(nodeActionVC, animated: true, completion: nil)
    }
    
    //MARK: - Private
    
    private func openFileNode(_ node: MEGANode, allNodes: [MEGANode]?) {
        if let nodeName = node.name as NSString?, nodeName.mnz_isVisualMediaPathExtension {
            let nodes = allNodes ?? [node]
            let index = nodes.firstIndex(where: { $0.handle == node.handle }) ?? 0
            let mediaNodes = NSMutableArray(array: nodes)
            guard let photoBrowserForMediaNode = MEGAPhotoBrowserViewController.photoBrowser(
                withMediaNodes: mediaNodes,
                api: MEGASdkManager.sharedMEGASdk(),
                displayMode: .cloudDrive,
                presenting: .none,
                preferredIndex: UInt(truncatingIfNeeded: index)
            ) else { return }
            navigationController?.present(photoBrowserForMediaNode, animated: true, completion: nil)
            return
        }
        node.mnz_open(in: navigationController, folderLink: false, fileLink: nil)
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
