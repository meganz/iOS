import MEGADomain
import MEGASDKRepo

@MainActor
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
        allNodes: [HandleEntity]? = nil,
        config: NodeBrowserConfig = .default
    ) {
        guard
            let megaNode = sdk.node(forHandle: nodeHandle)
        else { return }
        
        let allMegaNodes = allNodes?.compactMap { sdk.node(forHandle: $0) }
        
        switch megaNode.isFolder() {
        case true: openFolderNode(megaNode, config: config)
        case false: openFileNode(megaNode, allNodes: allMegaNodes, displayMode: config.displayMode, isFromSharedItem: config.isFromSharedItem)
        }
    }
    
    func openNode(node: MEGANode, allNodes: [MEGANode]?, config: NodeBrowserConfig = .default) {
        switch node.isFolder() {
        case true: openFolderNode(node, config: config)
        case false: openFileNode(node, allNodes: allNodes, displayMode: config.displayMode, isFromSharedItem: config.isFromSharedItem)
        }
    }
    
    func openNodeActions(_ nodeHandle: HandleEntity, sender: Any) {
        guard let navigationController = navigationController else { return }
        guard let node = sdk.node(forHandle: nodeHandle) else { return }
        
        let backupsUC = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let isBackupNode = backupsUC.isBackupNode(node.toNodeEntity())
        let delegate = NodeActionViewControllerGenericDelegate(
            viewController: navigationController,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: navigationController)
        )
        let nodeActionVC = NodeActionViewController(node: node,
                                                    delegate: delegate,
                                                    displayMode: .cloudDrive,
                                                    isIncoming: false,
                                                    isBackupNode: isBackupNode,
                                                    sender: sender)
        navigationController.present(nodeActionVC, animated: true, completion: nil)
    }
    
    // MARK: - Private
    // CRITICAL SECTION OF THE CODE
    // allNodes has to have all siblings of the node
    // for the image and audio player work properly
    private func openFileNode(
        _ node: MEGANode,
        allNodes: [MEGANode]?,
        displayMode: DisplayMode?,
        isFromSharedItem: Bool?
    ) {
        // if we do not have an image or video, we will jump deeper to see
        // if we have audio or other type of file
        guard node.name?.fileExtensionGroup.isVisualMedia == true else {
            node.mnz_open(in: navigationController, folderLink: false, fileLink: nil, messageId: nil, chatId: nil, isFromSharedItem: isFromSharedItem ?? false, allNodes: allNodes)
            return
        }
        
        // open MEGAPhotoBrowserViewController on the node and allow scrolling
        // through all visual media in the allNodes array
        openVisualMedia(node: node, allNodes: allNodes, displayMode: displayMode, isFromSharedItem: isFromSharedItem)
    }
    
    private func openVisualMedia(
        node: MEGANode,
        allNodes: [MEGANode]?,
        displayMode: DisplayMode?,
        isFromSharedItem: Bool?
    ) {
        // filter the visual media from allNodes so that photo browser displays only images and videos
        let allVisualMediaNodes: [MEGANode] = allNodes?.filter { node in
            node.name?.fileExtensionGroup.isVisualMedia == true
        } ?? []
        // `nodes` array cannot be empty (but can, and is often nil)
        // as photo browser assumes node is inside this array.
        // best to enforce it in here just before we initiate MEGAPhotoBrowserViewController
        // there's no easy way to enforce it in the method interface,
        // and we would need to check
        // type of node and allNode at each call site
        let nodes = allVisualMediaNodes.isNotEmpty ? allVisualMediaNodes : [node]
        let index = nodes.firstIndex(where: { $0.handle == node.handle }) ?? 0
        let mediaNodes = NSMutableArray(array: nodes)
        let isOwner = sdk.accessLevel(for: node) == .accessOwner
        let passedThroughDisplayMode: DisplayMode = displayMode?.carriedOverDisplayMode ?? .cloudDrive
        let photoBrowserForMediaNode = MEGAPhotoBrowserViewController.photoBrowser(
            withMediaNodes: mediaNodes,
            api: MEGASdk.sharedSdk,
            displayMode: isOwner ? passedThroughDisplayMode : .sharedItem,
            isFromSharedItem: isFromSharedItem ?? false,
            preferredIndex: UInt(truncatingIfNeeded: index)
        )
        navigationController?.present(photoBrowserForMediaNode, animated: true, completion: nil)
    }
    
    func openFolderNode(
        _ node: MEGANode,
        config: NodeBrowserConfig
    ) {
        let factory = CloudDriveViewControllerFactory.make(nc: navigationController)
        let vc = factory.buildBare(
            parentNode: node.toNodeEntity(),
            config: config
        )
        if let vc {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
