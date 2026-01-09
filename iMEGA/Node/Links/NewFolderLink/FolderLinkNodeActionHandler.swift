import FolderLink
import MEGAAppSDKRepo
import MEGADomain
import MEGASdk

final class FolderLinkNodeActionHandler: FolderLinkNodeActionHandlerProtocol {
    weak var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    func handle(action: FolderLinkNodeAction) {
        guard let node = MEGASdk.sharedFolderLink.node(forHandle: action.handle) else { return }
        showActions(for: node, from: action.sender)
    }
    
    private func showActions(for node: MEGANode, from sender: UIButton) {
        let backupRepository = BackupsRepository(sdk: MEGASdk.sharedFolderLink)
        let nodeActionViewController = NodeActionViewController(
            node: node,
            delegate: self,
            displayMode: .nodeInsideFolderLink,
            isIncoming: false,
            isBackupNode: backupRepository.isBackupNode(node.toNodeEntity()),
            sender: sender
        )

        navigationController?.present(nodeActionViewController, animated: true)
    }
}

extension FolderLinkNodeActionHandler: NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        switch action {
        case .download:
            downloadNodes([node])
        case .import:
            importNodes([node])
        case .saveToPhotos:
            saveToPhotos([node])
        default:
            break
        }
    }
    
    private func downloadNodes(_ nodes: [MEGANode]) {
        guard let navigationController else { return }
        DownloadLinkRouter(nodes: nodes.toNodeEntities(), isFolderLink: true, presenter: navigationController).start()
    }
    
    private func importNodes(_ nodes: [MEGANode]) {
        guard let navigationController else { return }
        ImportLinkRouter(
            isFolderLink: true,
            nodes: nodes,
            presenter: navigationController
        ).start()
    }
    
    private func saveToPhotos(_ nodes: [MEGANode]) {
        SaveToPhotosCoordinator
            .customProgressSVGErrorMessageDisplay(
                isFolderLink: true,
                configureProgress: {
                    TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
                })
            .saveToPhotos(nodes: nodes.toNodeEntities())
    }
}
