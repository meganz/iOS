import Foundation

final class HomeSearchResultRouter {

    private weak var navigationController: UINavigationController?

    private var nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate

    private lazy var nodeOpener = NodeOpener(navigationController: navigationController)

    init(
        navigationController: UINavigationController,
        nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate
    ) {
        self.navigationController = navigationController
        self.nodeActionViewControllerDelegate = nodeActionViewControllerDelegate
    }

    func didTapMoreAction(on node: MEGAHandle, button: UIButton) {
        guard let nodeActionViewController = NodeActionViewController(
            node: node,
            delegate: nodeActionViewControllerDelegate,
            displayMode: .cloudDrive,
            isIncoming: false,
            sender: button
        ) else { return }
        navigationController?.present(nodeActionViewController, animated: true, completion: nil)
    }

    func didTapNode(_ nodeHandle: MEGAHandle) {
        nodeOpener.openNode(nodeHandle)
    }
}

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

    private func openFileNode(_ node: MEGANode, allNodes: [MEGANode]?) {
        let nodeName = (node.name as NSString)
        if nodeName.mnz_isImagePathExtension || nodeName.mnz_isVideoPathExtension {
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
