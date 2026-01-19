import FolderLink
import MEGAAppSDKRepo
import MEGADomain
import MEGASdk

final class FolderLinkNodeActionHandler: FolderLinkNodeActionHandlerProtocol {
    weak var navigationController: UINavigationController?
    private let sdk: MEGASdk
    private var sendLinkDelegate: SendLinkToChatsDelegate?
    
    init(navigationController: UINavigationController?, sdk: MEGASdk = MEGASdk.sharedFolderLink) {
        self.navigationController = navigationController
        self.sdk = sdk
    }
    
    func handle(action: FolderLinkNodeAction) {
        guard let node = sdk.node(forHandle: action.handle) else { return }
        showActions(for: node, from: action.sender)
    }
    
    func handle(action: FolderLinkNodesAction) {
        switch action {
        case let .addToCloudDrive(nodeHandles):
            importNodes(nodeHandles: nodeHandles)
        case let .makeAvailableOffline(nodeHandles):
            downloadNodes(nodeHandles: nodeHandles)
        case let .saveToPhotos(nodeHandles):
            saveToPhotos(nodeHandles: nodeHandles)
        case let .sendToChat(link):
            showSendToChat(link: link)
        }
    }
    
    private func showActions(for node: MEGANode, from sender: UIButton) {
        let backupRepository = BackupsRepository(sdk: sdk)
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
    
    private func downloadNodes(nodeHandles: Set<HandleEntity>) {
        let nodes = nodeHandles.compactMap { sdk.node(forHandle: $0) }
        downloadNodes(nodes)
    }
    
    private func importNodes(nodeHandles: Set<HandleEntity>) {
        let nodes = nodeHandles.compactMap { sdk.node(forHandle: $0) }
        importNodes(nodes)
    }
    
    private func saveToPhotos(nodeHandles: Set<HandleEntity>) {
        let nodes = nodeHandles.compactMap { sdk.node(forHandle: $0) }
        saveToPhotos(nodes)
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
    
    private func showSendToChat(link: String) {
        if SAMKeychain.password(forService: "MEGA", account: "sessionV3") != nil {
            guard let sendToChatNavigationController =
                    UIStoryboard(
                        name: "Chat",
                        bundle: nil
                    ).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController,
                  let sendToViewController = sendToChatNavigationController.viewControllers.first as? SendToViewController else {
                return
            }
            
            sendToViewController.sendMode = .fileAndFolderLink
            self.sendLinkDelegate = SendLinkToChatsDelegate(link: link)
            sendToViewController.sendToViewControllerDelegate = self.sendLinkDelegate
            
            navigationController?.present(sendToChatNavigationController, animated: true)
            // IOS-11083 - trackSendToChatFolderLink
        } else {
            MEGALinkManager.linkSavedString = link
            MEGALinkManager.selectedOption = .sendNodeLinkToChat

            navigationController?.pushViewController(
                OnboardingUSPViewController(), animated: true)
            // trackSendToChatFolderLink - trackSendToChatFolderLinkNoAccountLogged
        }
    }
}
