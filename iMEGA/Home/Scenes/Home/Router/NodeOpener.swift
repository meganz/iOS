import MEGADomain
import MEGASDKRepo

final class NodeOpener {

    private weak var navigationController: UINavigationController?
    private var sdk = MEGASdk.sharedSdk
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    /// navigation to folder or open a file
    /// when file is a media, media browser with scroll through nodes in the allNodes array
    func openNode(
        nodeHandle: HandleEntity,
        allNodes: [HandleEntity] = [],
        config: CloudDriveViewControllerFactory.NodeBrowserConfig = .default
    ) {
        guard
            let megaNode = sdk.node(forHandle: nodeHandle)
        else { return }
        
        let allMegaNodes = allNodes.compactMap { sdk.node(forHandle: $0) }
        
        switch megaNode.isFolder() {
        case true: openFolderNode(megaNode, config: config)
        case false: openFileNode(megaNode, allNodes: allMegaNodes)
        }
    }
    
    func openNode(node: MEGANode, allNodes: [MEGANode]?, config: CloudDriveViewControllerFactory.NodeBrowserConfig = .default) {
        switch node.isFolder() {
        case true: openFolderNode(node, config: config)
        case false: openFileNode(node, allNodes: allNodes)
        }
    }
    
    func openNodeActions(_ nodeHandle: HandleEntity, sender: Any) {
        guard let navigationController = navigationController else { return }
        guard let node = sdk.node(forHandle: nodeHandle) else { return }
        
        let backupsUC = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let isBackupNode = backupsUC.isBackupNode(node.toNodeEntity())
        let delegate = NodeActionViewControllerGenericDelegate(viewController: navigationController)
        let nodeActionVC = NodeActionViewController(node: node,
                                                    delegate: delegate,
                                                    displayMode: .cloudDrive,
                                                    isIncoming: false,
                                                    isBackupNode: isBackupNode,
                                                    sender: sender)
        navigationController.present(nodeActionVC, animated: true, completion: nil)
    }
    
    // MARK: - Private
    
    private func openFileNode(_ node: MEGANode, allNodes: [MEGANode]?) {
        guard node.name?.fileExtensionGroup.isVisualMedia == true else {
            node.mnz_open(in: navigationController, folderLink: false, fileLink: nil, messageId: nil, chatId: nil, allNodes: allNodes)
            return
        }
        
        let nodes = allNodes ?? [node]
        let index = nodes.firstIndex(where: { $0.handle == node.handle }) ?? 0
        let mediaNodes = NSMutableArray(array: nodes)
        let photoBrowserForMediaNode = MEGAPhotoBrowserViewController.photoBrowser(
            withMediaNodes: mediaNodes,
            api: MEGASdk.sharedSdk,
            displayMode: .cloudDrive,
            preferredIndex: UInt(truncatingIfNeeded: index)
        )
        navigationController?.present(photoBrowserForMediaNode, animated: true, completion: nil)
    }
    
    func openFolderNode(
        _ node: MEGANode,
        config: CloudDriveViewControllerFactory.NodeBrowserConfig
    ) {
        let factory = CloudDriveViewControllerFactory.make(nc: navigationController)
        let vc = factory.buildBare(
            parentNode: node.toNodeEntity(),
            options: config
        )
        if let vc {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
