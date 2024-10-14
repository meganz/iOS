import ChatRepo
import MEGADomain
import MEGAPresentation
import MEGARepo
import MEGASDKRepo

@objc protocol TextFileEditable { }

@MainActor
final class TextEditorViewRouter: NSObject {
    private weak var navigationController: UINavigationController?
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    
    private var textFile: TextFile
    private let textEditorMode: TextEditorMode
    private let isFromSharedItem: Bool
    private var parentHandle: HandleEntity?
    private var nodeEntity: NodeEntity?
    private var browserVCDelegate: TargetFolderBrowserVCDelegate?
    private lazy var nodeAccessoryActionDelegate = DefaultNodeAccessoryActionDelegate()
    
    @objc convenience init(
        textFile: TextFile,
        textEditorMode: TextEditorMode,
        isFromSharedItem: Bool = false,
        node: MEGANode? = nil,
        presenter: UIViewController? = nil
    ) {
        self.init(textFile: textFile,
                  textEditorMode: textEditorMode,
                  isFromSharedItem: isFromSharedItem,
                  nodeEntity: node?.toNodeEntity(),
                  presenter: presenter)
    }
    
    init(
        textFile: TextFile,
        textEditorMode: TextEditorMode,
        isFromSharedItem: Bool = false,
        nodeEntity: NodeEntity? = nil,
        presenter: UIViewController? = nil
    ) {
        self.textFile = textFile
        self.textEditorMode = textEditorMode
        self.isFromSharedItem = isFromSharedItem
        self.nodeEntity = nodeEntity
        self.parentHandle = nodeEntity?.parentHandle
        self.presenter = presenter
    }
    
    convenience init(
        textFile: TextFile,
        textEditorMode: TextEditorMode,
        isFromSharedItem: Bool = false,
        parentHandle: HandleEntity? = nil,
        presenter: UIViewController
    ) {
        self.init(textFile: textFile, textEditorMode: textEditorMode, isFromSharedItem: isFromSharedItem, nodeEntity: nil, presenter: presenter)
        self.parentHandle = parentHandle
    }
}

extension TextEditorViewRouter: TextEditorViewRouting {
    
    // MARK: - U-R-MVVM Routing
    @objc func build() -> UIViewController {
        let sdk = MEGASdk.shared
        let nodeRepository = NodeRepository.newRepo
        let fileSystemRepository = FileSystemRepository(fileManager: FileManager.default)
        let uploadUC = UploadFileUseCase(uploadFileRepository: UploadFileRepository(sdk: sdk), fileSystemRepository: fileSystemRepository, nodeRepository: nodeRepository, fileCacheRepository: FileCacheRepository.newRepo)
        let downloadUC = DownloadNodeUseCase(
            downloadFileRepository: DownloadFileRepository(sdk: sdk),
            offlineFilesRepository: OfflineFilesRepository(store: MEGAStore.shareInstance(), sdk: sdk),
            fileSystemRepository: fileSystemRepository,
            nodeRepository: nodeRepository,
            nodeDataRepository: NodeDataRepository.newRepo,
            fileCacheRepository: FileCacheRepository.newRepo,
            mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
            preferenceRepository: PreferenceRepository.newRepo,
            offlineFileFetcherRepository: OfflineFileFetcherRepository.newRepo, 
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
            parentHandle: parentHandle,
            nodeEntity: nodeEntity
        )
        let vc = TextEditorViewController(viewModel: vm)
        vc.title = textFile.fileName
        baseViewController = vc
        
        let nav = MEGANavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        navigationController = nav
        
        return nav
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
        baseViewController?.present(browserNC, animated: true, completion: nil)
    }
    
    func dismissTextEditorVC() {
        dismiss()
    }
    
    func dismissBrowserVC() {
        dismiss()
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
        let nodeActionViewController = NodeActionViewController(node: node, delegate: delegate, displayMode: displayMode, isBackupNode: isBackupNode, isFromSharedItem: isFromSharedItem, sender: button)
        nodeActionViewController.accessoryActionDelegate = nodeAccessoryActionDelegate
        baseViewController?.present(nodeActionViewController, animated: true, completion: nil)
    }
    
    func showPreviewDocVC(fromFilePath path: String, showUneditableError: Bool) {
        let nc = UIStoryboard(name: "DocumentPreviewer", bundle: nil).instantiateViewController(withIdentifier: "previewDocumentNavigationID") as? MEGANavigationController
        let previewVC = nc?.viewControllers.first as? PreviewDocumentViewController
        previewVC?.filePath = path
        previewVC?.showUnknownEncodeHud = showUneditableError
        if let nodeHandle = nodeEntity?.handle {
            previewVC?.nodeHandle = nodeHandle
        }
        nc?.modalPresentationStyle = .fullScreen
        guard let navigationController = nc else { return }
        baseViewController?.dismiss(animated: true, completion: {
            self.presenter?.present(navigationController, animated: true, completion: nil)
        })
    }
    
    func importNode(nodeHandle: HandleEntity?) {
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
        guard let vc = baseViewController as? TextEditorViewController else { return }
        ExportFileRouter(presenter: vc, sender: button).export(node: node)
    }
    
    func showDownloadTransfer(node: NodeEntity) {
        guard let navigationController = navigationController else {
            return
        }
        
        let transfer = CancellableTransfer(handle: node.handle, name: nil, appData: nil, priority: false, isFile: node.isFile, type: .download)
        
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
        Task {
            let nodeActionUseCase = NodeActionUseCase(repo: NodeActionRepository.newRepo)
            _ = await nodeActionUseCase.unhide(nodes: [node])
        }
    }
}
