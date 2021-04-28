final class TextEditorViewRouter: NSObject {
    
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    
    private var textFile: TextFile
    private let textEditorMode: TextEditorMode
    private var parentHandle: MEGAHandle?
    private var nodeHandle: MEGAHandle?
    private var browserVCDelegate: TargetFolderBrowserVCDelegate?
    
    @objc init(
        textFile: TextFile,
        textEditorMode: TextEditorMode,
        nodeEntity: NodeEntity? = nil,
        presenter: UIViewController? = nil
    ) {
        self.textFile = textFile
        self.textEditorMode = textEditorMode
        self.nodeHandle = nodeEntity?.handle
        self.parentHandle = nodeEntity?.parentHandle
        self.presenter = presenter
    }
}

extension TextEditorViewRouter: TextEditorViewRouting {
    
    //MARK: - U-R-MVVM Routing
    @objc func build() -> UIViewController {
        let sdk = MEGASdkManager.sharedMEGASdk()
        let uploadUC = UploadFileUseCase(repo: UploadFileRepository(sdk: sdk))
        let downloadUC = DownloadFileUseCase(repo: DownloadFileRepository(sdk: sdk))
        let vm = TextEditorViewModel(
            router: self,
            textFile: textFile,
            textEditorMode: textEditorMode,
            uploadFileUseCase: uploadUC,
            downloadFileUseCase: downloadUC,
            parentHandle: parentHandle,
            nodeHandle: nodeHandle
        )
        let vc = TextEditorViewController(viewModel: vm)
        baseViewController = vc
        
        if textEditorMode == .load {
            vm.dispatch(.downloadFile)
        }
        let nav = MEGANavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
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
    
    func showActions(sender button: Any, handle: MEGAHandle?) {
        if handle != nil { nodeHandle = handle }
        
        guard let nodeHandle = nodeHandle,
              let nodeActionViewController = NodeActionViewController(
                nodeHandle: nodeHandle,
                delegate: self,
                displayMode: .textEditor,
                sender: button
        ) else { return }
        
        baseViewController?.present(nodeActionViewController, animated: true, completion: nil)
    }
    
    func showPreviewDocVC(fromFilePath path: String) {
        let nc = UIStoryboard(name: "DocumentPreviewer", bundle: nil).instantiateViewController(withIdentifier: "previewDocumentNavigationID") as? MEGANavigationController
        let previewVC = nc?.viewControllers.first as? PreviewDocumentViewController
        previewVC?.filePath = path
        nc?.modalPresentationStyle = .fullScreen
        guard let navigationController = nc else { return }
        presenter?.present(navigationController, animated: true, completion: nil)
    }
}

extension TextEditorViewRouter: NodeActionViewControllerDelegate {
    
    //MARK: - NodeActionViewControllerDelegate
    private func editTextFile() {
        guard let vc = baseViewController as? TextEditorViewController else { return }
        vc.executeCommand(.editFile)
    }
    
    private func download(_ node: MEGANode) {
        guard let vc = baseViewController else { return }
        node.mnz_fileLinkDownload(from: vc, isFolderLink: false)
    }
    
    private func sendToChat(_ node: MEGANode) {
        guard let vc = baseViewController else { return }
        node.mnz_sendToChat(in: vc)
    }
    
    private func share(_ node: MEGANode, _ sender: Any) {
        baseViewController?.present(UIActivityViewController(forNodes: [node], sender: sender), animated: true, completion: nil)
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        switch action {
        case .editTextFile: editTextFile()
        case .download: download(node)
        case .sendToChat: sendToChat(node)
        case .share: share(node, sender)
        default:
            break
        }
    }
}
