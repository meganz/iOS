@objc protocol TextFileEditable { }

final class TextEditorViewRouter: NSObject {
    private weak var navigationController: UINavigationController?
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    
    private var textFile: TextFile
    private let textEditorMode: TextEditorMode
    private var parentHandle: MEGAHandle?
    private var nodeEntity: NodeEntity?
    private var browserVCDelegate: TargetFolderBrowserVCDelegate?
    
    @objc convenience init(
        textFile: TextFile,
        textEditorMode: TextEditorMode,
        node: MEGANode? = nil,
        presenter: UIViewController? = nil
    ) {
        self.init(textFile: textFile,
                  textEditorMode: textEditorMode,
                  nodeEntity: node.map { NodeEntity(node: $0) },
                  presenter: presenter)
    }
    
    init(
        textFile: TextFile,
        textEditorMode: TextEditorMode,
        nodeEntity: NodeEntity? = nil,
        presenter: UIViewController? = nil
    ) {
        self.textFile = textFile
        self.textEditorMode = textEditorMode
        self.nodeEntity = nodeEntity
        self.parentHandle = nodeEntity?.parentHandle
        self.presenter = presenter
    }
    
    convenience init(
        textFile: TextFile,
        textEditorMode: TextEditorMode,
        parentHandle: MEGAHandle? = nil,
        presenter: UIViewController
    ) {
        self.init(textFile: textFile, textEditorMode: textEditorMode, nodeEntity: nil, presenter: presenter)
        self.parentHandle = parentHandle
    }
}

extension TextEditorViewRouter: TextEditorViewRouting {
    
    //MARK: - U-R-MVVM Routing
    @objc func build() -> UIViewController {
        let sdk = MEGASdkManager.sharedMEGASdk()
        let nodeRepository = NodeRepository.default
        let fileSystemRepository = FileSystemRepository(fileManager: FileManager.default)
        let uploadUC = UploadFileUseCase(uploadFileRepository: UploadFileRepository(sdk: sdk), fileSystemRepository: fileSystemRepository, nodeRepository: nodeRepository, fileCacheRepository: FileCacheRepository.default)
        let downloadUC = DownloadNodeUseCase(
            downloadFileRepository: DownloadFileRepository(sdk: sdk),
            offlineFilesRepository: OfflineFilesRepository(store: MEGAStore.shareInstance(), sdk: sdk),
            fileSystemRepository: fileSystemRepository,
            nodeRepository: nodeRepository,
            fileCacheRepository: FileCacheRepository.default)
        let nodeActionUC = NodeActionUseCase(repo: NodeActionRepository(sdk: sdk, nodeHandle: nodeEntity?.handle))
        let vm = TextEditorViewModel(
            router: self,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: uploadUC,
            downloadNodeUseCase: downloadUC,
            nodeActionUseCase: nodeActionUC,
            parentHandle: parentHandle,
            nodeEntity: nodeEntity
        )
        let vc = TextEditorViewController(viewModel: vm)
        baseViewController = vc
        
        let nav = MEGANavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        navigationController = nav
        
        return nav
    }
    
    @objc func start() {
        presenter?.present(build(), animated: true, completion: nil)
    }
    
    //MARK: - TextEditorViewRouting
    func chooseParentNode(completion: @escaping (MEGAHandle) -> Void) {
        let storyboard = UIStoryboard(name: "Cloud", bundle: nil)
        guard let browserVC = storyboard.instantiateViewController(withIdentifier: "BrowserViewControllerID") as? BrowserViewController
        else { return }
        if browserVCDelegate == nil  {
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
    
    func showActions(nodeHandle: MEGAHandle, delegate: NodeActionViewControllerDelegate, sender button: Any) {
        guard let node = MEGASdkManager.sharedMEGASdk().node(forHandle: nodeHandle) else {
            return
        }
        
        let displayMode: DisplayMode = node.mnz_isInRubbishBin() ? .rubbishBin : .textEditor
        let nodeActionViewController = NodeActionViewController(node: node, delegate: delegate, displayMode: displayMode, sender: button)
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
    
    func importNode(nodeHandle: MEGAHandle?) {
        guard let nodeHandle = nodeHandle,
              let node = MEGASdkManager.sharedMEGASdk().node(forHandle: nodeHandle) else {
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
        
        let transfer = CancellableTransfer(handle: node.handle, path: Helper.relativePathForOffline(), name: nil, appData: nil, priority: false, isFile: node.isFile, type: .download)
        
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
        let nodeInfoViewController = NodeInfoViewController.instantiate(withNode: node, delegate: nil)
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
    
    func shareLink(from nodeHandle: MEGAHandle) {
        guard let node = MEGASdkManager.sharedMEGASdk().node(forHandle: nodeHandle) else {
            return
        }
        
        CopyrightWarningViewController.presentGetLinkViewController(for: [node], in: baseViewController)
    }
    
    func removeLink(from nodeHandle: MEGAHandle) {
        guard let node = MEGASdkManager.sharedMEGASdk().node(forHandle: nodeHandle) else {
            return
        }
        
        node.mnz_removeLink()
    }
}
