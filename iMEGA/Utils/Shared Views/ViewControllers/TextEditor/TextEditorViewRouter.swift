import ChatRepo
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGAPreference
import MEGARepo
import MEGATextEditor

@objc protocol TextFileEditable { }

@MainActor
final class TextEditorViewRouter: NSObject {
    private weak var navigationController: UINavigationController?
    private weak var baseViewController: UIViewController?
    /// The folder picker of a new file, while it is on screen.
    private weak var browserNavigationController: UINavigationController?
    private weak var presenter: UIViewController?
    
    private var textFile: TextFile
    private let textEditorMode: TextEditorMode
    private let isFromSharedItem: Bool
    private var parentHandle: HandleEntity?
    private var nodeEntity: NodeEntity?
    /// Kept alongside `nodeEntity` so a link node, which is in no SDK tree, can still be downloaded.
    private var megaNode: MEGANode?
    private var browserVCDelegate: TargetFolderBrowserVCDelegate?
    private lazy var nodeAccessoryActionDelegate = DefaultNodeAccessoryActionDelegate()
    private let isMarkdownEditorEnabled: Bool
    /// True for a file from a folder link or a file link. The file is in no SDK tree of the account,
    /// so download and import use the link flows.
    private var isLink = false
    /// The public link of a file link. It is nil for a file inside a folder link.
    private var fileLink: String?
    
    @objc convenience init(
        textFile: TextFile,
        textEditorMode: TextEditorMode,
        isFromSharedItem: Bool = false,
        node: MEGANode? = nil,
        presenter: UIViewController? = nil,
        isMarkdownEditorEnabled: Bool,
        isLink: Bool = false,
        fileLink: String? = nil
    ) {
        self.init(textFile: textFile,
                  textEditorMode: textEditorMode,
                  isFromSharedItem: isFromSharedItem,
                  nodeEntity: node?.toNodeEntity(),
                  presenter: presenter,
                  isMarkdownEditorEnabled: isMarkdownEditorEnabled)
        self.megaNode = node
        self.isLink = isLink
        self.fileLink = fileLink
    }
    
    init(
        textFile: TextFile,
        textEditorMode: TextEditorMode,
        isFromSharedItem: Bool = false,
        nodeEntity: NodeEntity? = nil,
        presenter: UIViewController? = nil,
        isMarkdownEditorEnabled: Bool
    ) {
        self.textFile = textFile
        self.textEditorMode = textEditorMode
        self.isFromSharedItem = isFromSharedItem
        self.nodeEntity = nodeEntity
        self.parentHandle = nodeEntity?.parentHandle
        self.presenter = presenter
        self.isMarkdownEditorEnabled = isMarkdownEditorEnabled
    }
    
    convenience init(
        textFile: TextFile,
        textEditorMode: TextEditorMode,
        isFromSharedItem: Bool = false,
        parentHandle: HandleEntity? = nil,
        presenter: UIViewController,
        isMarkdownEditorEnabled: Bool
    ) {
        self.init(
            textFile: textFile,
            textEditorMode: textEditorMode,
            isFromSharedItem: isFromSharedItem,
            nodeEntity: nil,
            presenter: presenter,
            isMarkdownEditorEnabled: isMarkdownEditorEnabled
        )
        self.parentHandle = parentHandle
    }

    // MARK: - Markdown

    /// `.load` uses the node size, so the size check runs before the download. A new file has no node and size 0.
    /// `.view` keeps the legacy screen: only `buildMarkdownScreen()` shows checked UTF-8 text on the Markdown screen.
    private var screenRoute: MarkdownTextEditorRoute {
        guard textEditorMode != .view else { return .otherFile }
        return MarkdownTextEditorRoute(fileName: textFile.fileName, sizeInBytes: nodeEntity?.size ?? 0, isEnabled: isMarkdownEditorEnabled)
    }

    /// The alert for a Markdown file over the preview limit. Download works like Export: the file opens in another app.
    /// Without a node or a presenter there is nothing to export, so only Cancel shows.
    static func makeMarkdownTooLargeAlert(node: NodeEntity?, presenter: UIViewController?) -> UIAlertController {
        let size = String.memoryStyleString(fromByteCount: Int64(clamping: node?.size ?? 0))
        let alert = UIAlertController(
            title: Strings.Localizable.MarkdownEditor.FileTooLarge.title,
            message: Strings.Localizable.MarkdownEditor.FileTooLarge.message(size),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
        if let node, let presenter {
            alert.addAction(UIAlertAction(title: Strings.Localizable.download, style: .default) { [weak presenter] _ in
                guard let presenter else { return }
                ExportFileRouter(presenter: presenter, sender: presenter.view).export(node: node)
            })
        }
        return alert
    }

    /// Shows the text file on the Markdown screen. The caller has already checked the size and decoded the text as UTF-8.
    func buildMarkdownScreen() -> UIViewController {
        makeNavigationController(rootedAt: MarkdownTextEditorViewController(viewModel: makeViewModel(isMarkdownScreen: true)))
    }
}

extension TextEditorViewRouter: TextEditorViewRouting {
    
    // MARK: - U-R-MVVM Routing
    @objc func build() -> UIViewController {
        switch screenRoute {
        case .tooLarge:
            return Self.makeMarkdownTooLargeAlert(node: nodeEntity, presenter: presenter)
        case .markdownFile:
            return buildMarkdownScreen()
        case .otherFile:
            return makeNavigationController(rootedAt: TextEditorViewController(viewModel: makeViewModel(isMarkdownScreen: false)))
        }
    }

    private func makeNavigationController(rootedAt vc: UIViewController) -> MEGANavigationController {
        vc.title = textFile.fileName
        baseViewController = vc

        let nav = MEGANavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        navigationController = nav

        return nav
    }

    private func makeViewModel(isMarkdownScreen: Bool) -> TextEditorViewModel {
        let sdk = MEGASdk.shared
        let nodeRepository = NodeRepository.newRepo
        let fileSystemRepository = FileSystemRepository.sharedRepo
        let uploadUC = UploadFileUseCase(uploadFileRepository: UploadFileRepository(sdk: sdk), fileSystemRepository: fileSystemRepository, nodeRepository: nodeRepository, fileCacheRepository: FileCacheRepository.newRepo)
        let downloadUC = DownloadNodeUseCase(
            downloadFileRepository: DownloadFileRepository(
                sdk: sdk,
                chatNodeProvider: ChatMEGANodeProvider(chatSdk: MEGAChatSdk.sharedChatSdk, sdk: sdk),
                preresolvedNodes: megaNode.map { [$0.handle: $0] } ?? [:]
            ),
            fileSystemRepository: fileSystemRepository,
            nodeRepository: nodeRepository,
            nodeDataRepository: NodeDataRepository.newRepo,
            fileCacheRepository: FileCacheRepository.newRepo,
            mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
            preferenceRepository: PreferenceRepository.newRepo, 
            chatNodeRepository: ChatNodeRepository.newRepo,
            downloadChatRepository: DownloadChatRepository.newRepo)
        let nodeDataUC = NodeUseCase(nodeDataRepository: NodeDataRepository.newRepo, nodeValidationRepository: NodeValidationRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let backupsUC = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let vm = TextEditorViewModel(
            router: self,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: uploadUC,
            downloadNodeUseCase: downloadUC,
            nodeUseCase: nodeDataUC,
            backupsUseCase: backupsUC,
            resumeTextPositionUseCase: ResumeTextPositionUseCase(preferenceUseCase: PreferenceUseCase.default),
            parentHandle: parentHandle,
            nodeEntity: nodeEntity,
            isMarkdownScreen: isMarkdownScreen,
            isLink: isLink
        )
        return vm
    }

    @objc func start() {
        presenter?.present(build(), animated: true, completion: nil)
    }
    
    // MARK: - TextEditorViewRouting
    func chooseParentNode(completion: @escaping (HandleEntity) -> Void) {
        let storyboard = UIStoryboard(name: "Cloud", bundle: nil)
        guard let browserVC = storyboard.instantiateViewController(withIdentifier: "BrowserViewControllerID") as? BrowserViewController
        else { return }
        if browserVCDelegate == nil {
            browserVCDelegate = TargetFolderBrowserVCDelegate()
        }
        
        browserVCDelegate?.completion = { node in
            completion(node.handle)
        }
        browserVC.browserViewControllerDelegate = browserVCDelegate
        browserVC.browserAction = .newFileSave
        let browserNC = MEGANavigationController(rootViewController: browserVC)
        browserNC.setToolbarHidden(false, animated: false)
        browserNavigationController = browserNC
        baseViewController?.present(browserNC, animated: true, completion: nil)
    }
    
    /// Closes the editor together with any screen on top of it, such as the folder picker.
    func dismissTextEditorVC() {
        guard let presentingViewController = navigationController?.presentingViewController else {
            dismiss()
            return
        }
        presentingViewController.dismiss(animated: true, completion: nil)
    }
    
    /// Closes only the folder picker. Without a picker on screen it does nothing, so the editor stays open.
    func dismissBrowserVC() {
        browserNavigationController?.dismiss(animated: true, completion: nil)
    }
    
    private func dismiss() {
        baseViewController?.dismiss(animated: true, completion: nil)
    }
    
    func showActions(nodeHandle: HandleEntity, delegate: some NodeActionViewControllerDelegate, sender button: Any) {
        guard let node = MEGASdk.shared.node(forHandle: nodeHandle) else {
            return
        }
        
        let backupsUC = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let isBackupNode = backupsUC.isBackupNode(node.toNodeEntity())
        let displayMode: DisplayMode = node.mnz_isInRubbishBin() ? .rubbishBin : .textEditor
        let nodeActionViewController = NodeActionViewController(
            node: node,
            delegate: delegate,
            displayMode: displayMode,
            isBackupNode: isBackupNode,
            isFromSharedItem: isFromSharedItem,
            isSelectionEnabled: false,
            sender: button
        )
        nodeActionViewController.accessoryActionDelegate = nodeAccessoryActionDelegate
        baseViewController?.present(nodeActionViewController, animated: true, completion: nil)
    }
    
    func showPreviewDocVC(fromFilePath path: String, showUneditableError: Bool) {
        let nc = UIStoryboard(name: "DocumentPreviewer", bundle: nil).instantiateViewController(withIdentifier: "previewDocumentNavigationID") as? MEGANavigationController
        let previewVC = nc?.viewControllers.first as? PreviewDocumentViewController
        previewVC?.filePath = path
        previewVC?.showUnknownEncodeHud = showUneditableError
        if isLink {
            previewVC?.node = megaNode
            previewVC?.isLink = true
            previewVC?.fileLink = fileLink
        } else if let nodeHandle = nodeEntity?.handle {
            previewVC?.nodeHandle = nodeHandle
        }
        nc?.modalPresentationStyle = .fullScreen
        guard let navigationController = nc else { return }
        baseViewController?.dismiss(animated: true, completion: {
            self.presenter?.present(navigationController, animated: true, completion: nil)
        })
    }
    
    func importNode(nodeHandle: HandleEntity?) {
        if isLink {
            importLinkNode()
            return
        }
        guard let nodeHandle = nodeHandle,
              let node = MEGASdk.shared.node(forHandle: nodeHandle) else {
            return
        }
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            let storyboard = UIStoryboard(name: "Cloud", bundle: nil)
            guard let browserVC = storyboard.instantiateViewController(withIdentifier: "BrowserViewControllerID") as? BrowserViewController
            else { return }
            browserVC.selectedNodesArray = [node]
            browserVC.browserAction = .import
            let browserNC = MEGANavigationController(rootViewController: browserVC)
            browserNC.setToolbarHidden(false, animated: false)
            baseViewController?.present(browserNC, animated: true, completion: nil)
        }
    }
    
    func exportFile(from node: NodeEntity, sender button: Any) {
        guard let vc = baseViewController else { return }
        ExportFileRouter(presenter: vc, sender: button).export(node: node)
    }
    
    func showDownloadTransfer(node: NodeEntity) {
        guard let navigationController = navigationController else {
            return
        }
        if isLink {
            downloadLinkNode(node, presenter: navigationController)
            return
        }
        
        let transfer = CancellableTransfer(handle: node.handle, name: node.name, appData: nil, priority: false, isFile: node.isFile, type: .download)

        CancellableTransferRouter(presenter: navigationController, transfers: [transfer], transferType: .download, isFolderLink: false).start()
    }
    
    func sendToChat(node: MEGANode) {
        guard let vc = baseViewController else {
            return
        }
        node.mnz_sendToChat(in: vc)
    }
    
    func restoreTextFile(node: MEGANode) {
        dismissTextEditorVC()
        node.mnz_restore()
    }

    func viewInfo(node: MEGANode) {
        let viewModel = NodeInfoViewModel(
            withNode: node,
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo),
            backupUseCase: BackupsUseCase(
                backupsRepository: BackupsRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            )
        )
        let nodeInfoViewController = NodeInfoViewController.instantiate(withViewModel: viewModel, delegate: nil)
        baseViewController?.present(nodeInfoViewController, animated: true, completion: nil)
    }

    func viewVersions(node: MEGANode) {
        guard let controller = baseViewController else { return }
        node.mnz_showVersions(in: controller)
    }

    func removeTextFile(node: MEGANode) {
        guard let controller = baseViewController else { return }
        node.mnz_remove(in: controller, completion: nil)
    }
    
    func moveToRubbishBin(node: MEGANode) {
        guard let controller = baseViewController else { return }
        node.mnz_askToMoveToTheRubbishBin(in: controller)
    }

    func shareLink(from nodeHandle: HandleEntity) {
        guard let baseViewController,
              let node = MEGASdk.shared.node(forHandle: nodeHandle) else {
            return
        }
        
        GetLinkRouter(presenter: baseViewController,
                      nodes: [node]).start()
    }
    
    func removeLink(from nodeHandle: HandleEntity) {
        guard let baseViewController, let node = MEGASdk.shared.node(forHandle: nodeHandle) else {
            return
        }
        
        let router = ActionWarningViewRouter(presenter: baseViewController, nodes: [node.toNodeEntity()], actionType: .removeLink, onActionStart: {
            SVProgressHUD.show()
        }, onActionFinish: {
            switch $0 {
            case .success(let message):
                SVProgressHUD.showSuccess(withStatus: message)
            case .failure:
                SVProgressHUD.dismiss()
            }
        })
        router.start()
    }
    
    func hide(node: NodeEntity) {
        guard let baseViewController else {
            return
        }
        HideFilesAndFoldersRouter(presenter: baseViewController)
            .hideNodes([node])
    }
    
    func unhide(node: NodeEntity) {
        guard let baseViewController else { return }
        HideFilesAndFoldersRouter(presenter: baseViewController)
            .unhideNodes([node])
    }
}

// MARK: - Links
extension TextEditorViewRouter {
    /// A file link downloads by its public link. A file inside a folder link downloads through the folder link SDK.
    private func downloadLinkNode(_ node: NodeEntity, presenter: UIViewController) {
        if let fileLink, let linkURL = URL(string: fileLink) {
            DownloadLinkRouter(link: linkURL, isFolderLink: false, presenter: presenter).start()
        } else {
            DownloadLinkRouter(nodes: [node], isFolderLink: true, presenter: presenter).start()
        }
    }

    /// The import keeps the text screen open, like the document preview. Without a session it shows onboarding first.
    private func importLinkNode() {
        guard let megaNode, let baseViewController else { return }
        ImportLinkRouter(
            isFolderLink: fileLink == nil,
            nodes: [megaNode],
            presenter: baseViewController,
            dismissBeforePresent: false
        ).start()
    }
}
