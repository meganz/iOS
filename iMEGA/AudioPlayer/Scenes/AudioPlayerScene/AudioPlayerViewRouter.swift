import Foundation

final class AudioPlayerViewRouter: NSObject, AudioPlayerViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private var playerHandler: AudioPlayerHandlerProtocol
    private var node: MEGANode?
    private var fileLink: String?
    private var isFolderLink: Bool?
    private var selectedFile: String?
    private var relatedFiles: [String]?
    private var nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate?
    private var fileLinkActionViewControllerDelegate : FileLinkActionViewControllerDelegate?
    
    // Nodes, File Links, Folder Links Init
    @objc init(node: MEGANode, fileLink: String?, isFolderLink: Bool, presenter: UIViewController, playerHandler: AudioPlayerHandlerProtocol) {
        self.presenter = presenter
        self.playerHandler = playerHandler
        self.node = node
        self.fileLink = fileLink
        self.isFolderLink = isFolderLink
        super.init()
    }
    
    // Offline Files Init
    @objc init(selectedFile: String, relatedFiles: [String]?, presenter: UIViewController, playerHandler: AudioPlayerHandlerProtocol) {
        self.presenter = presenter
        self.playerHandler = playerHandler
        self.selectedFile = selectedFile
        self.relatedFiles = relatedFiles
        super.init()
    }
    
    func build() -> UIViewController {
       
        let vc = UIStoryboard(name: "AudioPlayer", bundle: nil)
            .instantiateViewController(withIdentifier: "AudioPlayerViewControllerID") as! AudioPlayerViewController
        
        if let node = node {
            vc.viewModel = AudioPlayerViewModel(node: node,
                                                fileLink: fileLink,
                                                isFolderLink: isFolderLink ?? false,
                                                router: self,
                                                playerHandler: playerHandler,
                                                nodeInfoUseCase: NodeInfoUseCase(),
                                                streamingInfoUseCase: StreamingInfoUseCase())
            
        } else if let filePaths = relatedFiles, let selectedFilePath = selectedFile {
            vc.viewModel = AudioPlayerViewModel(selectedFile: selectedFilePath,
                                                filePaths: filePaths,
                                                router: self,
                                                playerHandler: playerHandler,
                                                offlineInfoUseCase: OfflineFileInfoUseCase())
        }

        baseViewController = vc
        
        if let fileLink = fileLink {
            self.fileLinkActionViewControllerDelegate = FileLinkActionViewControllerDelegate(link: fileLink, viewController: vc)
        } else {
            self.nodeActionViewControllerDelegate = NodeActionViewControllerGenericDelegate(viewController: vc)
        }
        
        return fileLink != nil ? MEGANavigationController(rootViewController: vc) : vc
    }
    
    @objc func start() {
        presenter?.present(build(), animated: true, completion: nil)
    }
    
    // MARK: - UI Actions
    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
    
    func goToPlaylist() {
        guard let presenter = self.baseViewController else { return }
        AudioPlaylistViewRouter(presenter: presenter, parentNode: node?.parent, playerHandler: playerHandler).start()
    }
    
    func showMiniPlayer(shouldReload: Bool) {
        guard let presenter = presenter else { return }
        
        playerHandler.initMiniPlayer(node: nil, fileLink: fileLink, filePaths: relatedFiles, isFolderLink: isFolderLink ?? false, presenter: presenter, shouldReloadPlayerInfo: shouldReload, shouldResetPlayer: false)
    }
    
    func showOfflineMiniPlayer(file: String, shouldReload: Bool) {
        guard let presenter = presenter else { return }
        
        playerHandler.initMiniPlayer(node: nil, fileLink: file, filePaths: relatedFiles, isFolderLink: false, presenter: presenter, shouldReloadPlayerInfo: shouldReload, shouldResetPlayer: false)
    }
    
    func importNode(_ node: MEGANode) {
        fileLinkActionViewControllerDelegate?.importNode(node)
    }
    
    func share() {
        fileLinkActionViewControllerDelegate?.shareLink()
    }
    
    func sendToChat() {
        fileLinkActionViewControllerDelegate?.sendToChat()
    }
    
    func showAction(for node: MEGANode, sender: Any) {
        let displayMode: DisplayMode = node.mnz_isInRubbishBin() ? .rubbishBin : .cloudDrive
        let nodeActionViewController = NodeActionViewController(
                node: node,
                delegate: self,
                displayMode: displayMode,
                isInVersionsView: isPlayingFromVersionView(),
                sender: sender)
        
        baseViewController?.present(nodeActionViewController, animated: true, completion: nil)
    }
    
    private func isPlayingFromVersionView() -> Bool {
        return presenter?.isKind(of: NodeVersionsViewController.self) == true
    }
}

extension AudioPlayerViewRouter: NodeActionViewControllerDelegate {

    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        fileLink != nil ?
            fileLinkActionViewControllerDelegate?.nodeAction(nodeAction, didSelect: action, for: node, from: sender) :
            nodeActionViewControllerDelegate?.nodeAction(nodeAction, didSelect: action, for: node, from: sender)
    }
}

