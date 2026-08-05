import FolderLink
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGASdk

final class FolderLinkNodeActionHandler: FolderLinkNodeActionHandlerProtocol {
    weak var navigationController: UINavigationController?
    private let sdk: MEGASdk
    private var sendLinkDelegate: SendLinkToChatsDelegate?
    /// Kept from the action whose sheet is on screen so the Select row can be handed back to the folder
    /// link: the sheet's delegate reports the node, not the action it came from. Cleared once it fires,
    /// and replaced by the next sheet, so it never outlives the presentation it belongs to for long.
    private var presentedNodeSelectHandler: (@MainActor () -> Void)?

    init(navigationController: UINavigationController?, sdk: MEGASdk = MEGASdk.sharedFolderLink) {
        self.navigationController = navigationController
        self.sdk = sdk
    }
    
    func handle(action: FolderLinkNodeAction) {
        guard let node = sdk.node(forHandle: action.handle) else { return }
        presentedNodeSelectHandler = action.selectHandler
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
        case let .downloadToFiles(nodeHandles):
            exportNodes(nodeHandles: nodeHandles)
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
            isSelectionEnabled: true,
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
        case .exportFile:
            exportNode(node, from: sender)
        case .select:
            presentedNodeSelectHandler?()
            presentedNodeSelectHandler = nil
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
    
    /// Placeholder until IOS-11735 builds the real Download flow. `ExportFileRouter` only exports files,
    /// so a selected folder is silently dropped here — the SDK has no compressed download, so covering
    /// folders means downloading the tree and archiving it on device, which IOS-11735 owns along with
    /// the behaviour design picks for mixed file and folder selections.
    private func exportNodes(nodeHandles: Set<HandleEntity>) {
        guard let navigationController else { return }
        let nodes = nodeHandles.compactMap { sdk.node(forHandle: $0) }
        ExportFileRouter(presenter: navigationController, sender: navigationController.view, isFolderLink: true)
            .export(nodes: nodes.toNodeEntities())
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
    
    /// Saving a non-media file to the device goes through the system share sheet, where Save to Files
    /// lives. The node sits in the folder link SDK, hence the flag.
    private func exportNode(_ node: MEGANode, from sender: Any) {
        guard let navigationController else { return }
        ExportFileRouter(presenter: navigationController, sender: sender, isFolderLink: true)
            .export(node: node.toNodeEntity())
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
            DIContainer.tracker.trackAnalyticsEvent(with: SendToChatFolderLinkButtonPressedEvent())
        } else {
            MEGALinkManager.linkSavedString = link
            MEGALinkManager.selectedOption = .sendNodeLinkToChat

            navigationController?.pushViewController(
                OnboardingUSPViewController(), animated: true)
            DIContainer.tracker.trackAnalyticsEvent(with: SendToChatFolderLinkNoAccountLoggedButtonPressedEvent())
        }
    }
}
