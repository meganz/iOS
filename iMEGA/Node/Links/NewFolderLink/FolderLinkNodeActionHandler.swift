import FolderLink
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGARepo
import MEGASdk

final class FolderLinkNodeActionHandler: FolderLinkNodeActionHandlerProtocol {
    weak var navigationController: UINavigationController?
    private let sdk: MEGASdk
    /// The storage pre-check ships with the revamped folder link only, so the legacy surfaces keep
    /// behaving exactly as before.
    private let isLinkRevampEnabled: Bool
    /// `nonisolated` so that sizing can be read from off the main actor — see `requiredBytes(for:)`.
    private nonisolated let nodeUseCase: any NodeUseCaseProtocol
    private let storageChecker: any DeviceStorageChecking
    private let notEnoughStorageAlertRouter: any NotEnoughStorageAlertRouting
    /// Set while a transfer is being set up. Sizing the selection is asynchronous, so without this a
    /// second tap during that window starts a parallel run, and both then try to present an alert or a
    /// share sheet — UIKit drops the second presentation, leaving the user with nothing.
    private var isSettingUpTransfer = false
    private var sendLinkDelegate: SendLinkToChatsDelegate?
    /// Kept from the action whose sheet is on screen so the Select row can be handed back to the folder
    /// link: the sheet's delegate reports the node, not the action it came from. Cleared once it fires,
    /// and replaced by the next sheet, so it never outlives the presentation it belongs to for long.
    private var presentedNodeSelectHandler: (@MainActor () -> Void)?

    init(
        navigationController: UINavigationController?,
        isLinkRevampEnabled: Bool,
        sdk: MEGASdk = MEGASdk.sharedFolderLink,
        nodeUseCase: some NodeUseCaseProtocol = NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        ),
        storageChecker: some DeviceStorageChecking = DeviceStorageChecker(
            deviceStorageUseCase: DeviceStorageUseCase(deviceStorageRepository: DeviceStorageRepository.newRepo)
        ),
        notEnoughStorageAlertRouter: (any NotEnoughStorageAlertRouting)? = nil
    ) {
        self.navigationController = navigationController
        self.isLinkRevampEnabled = isLinkRevampEnabled
        self.sdk = sdk
        self.nodeUseCase = nodeUseCase
        self.storageChecker = storageChecker
        self.notEnoughStorageAlertRouter = notEnoughStorageAlertRouter
            ?? NotEnoughStorageAlertRouter(presenter: navigationController)
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
    
    /// Placeholder until IOS-12333 builds the real Download flow. `ExportFileRouter` only exports files,
    /// so a selected folder is silently dropped here — the SDK has no compressed download, so covering
    /// folders means downloading the tree and archiving it on device, which IOS-12333 owns along with
    /// the behaviour design picks for mixed file and folder selections.
    private func exportNodes(nodeHandles: Set<HandleEntity>) {
        let nodes = nodeHandles.compactMap { sdk.node(forHandle: $0) }
        Task { await settingUpTransfer { await startExport(of: nodes) } }
    }

    private func startExport(of nodes: [MEGANode]) async {
        guard let navigationController, await confirmEnoughStorage(for: nodes) else { return }
        ExportFileRouter(presenter: navigationController, sender: navigationController.view, isFolderLink: true)
            .export(nodes: nodes.toNodeEntities())
    }
    
    private func downloadNodes(_ nodes: [MEGANode]) {
        Task { await settingUpTransfer { await startDownload(of: nodes) } }
    }

    private func startDownload(of nodes: [MEGANode]) async {
        guard let navigationController, await confirmEnoughStorage(for: nodes) else { return }
        DownloadLinkRouter(nodes: nodes.toNodeEntities(), isFolderLink: true, presenter: navigationController).start()
    }

    /// Runs `start` unless another transfer is already being set up, so repeated taps on a bottom bar
    /// button collapse into one. Only covers the set-up window: once the transfer is handed to its
    /// router, the transfers UI takes over reporting it.
    private func settingUpTransfer(_ start: () async -> Void) async {
        guard !isSettingUpTransfer else { return }
        isSettingUpTransfer = true
        defer { isSettingUpTransfer = false }

        await start()
    }

    /// Both saving offline and exporting to Files write the whole selection to the device, so each one
    /// asks about free space up front instead of letting the SDK fail file by file mid transfer.
    ///
    /// Reports the shortfall as well as returning the decision, since all three entry points warn the
    /// same way and there is nothing for them to add once the answer is no.
    private func confirmEnoughStorage(for nodes: [MEGANode]) async -> Bool {
        guard isLinkRevampEnabled else { return true }

        let bytes = await requiredBytes(for: nodes)
        switch await storageChecker.verdict(forAdditionalBytes: bytes) {
        case .fits:
            return true
        case let .doesNotFit(requiredBytes, availableBytes):
            notEnoughStorageAlertRouter.showNotEnoughStorage(
                requiredBytes: requiredBytes,
                availableBytes: availableBytes
            )
            return false
        }
    }

    /// `nonisolated` because sizing a folder makes the SDK walk its whole tree, which would block the
    /// main actor for a large folder link.
    ///
    /// The total is an upper bound: it charges the device for the whole selection, while a download
    /// skips whatever is already offline and an export reuses whatever is already cached. Erring on the
    /// high side only ever warns too eagerly, never too late, and IOS-12333 replaces this with the byte
    /// count the real download plan reports once that plan exists.
    private nonisolated func requiredBytes(for nodes: [MEGANode]) async -> UInt64 {
        nodes.toNodeEntities().reduce(UInt64.zero) { total, node in
            total + (nodeUseCase.sizeFor(node: node) ?? 0)
        }
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
        Task { await settingUpTransfer { await startExport(of: node, from: sender) } }
    }

    private func startExport(of node: MEGANode, from sender: Any) async {
        guard let navigationController, await confirmEnoughStorage(for: [node]) else { return }
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
