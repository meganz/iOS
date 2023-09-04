import Foundation
import MEGADomain
import MEGAPresentation

final class AudioPlayerViewRouter: NSObject, AudioPlayerViewRouting {
    private let configEntity: AudioPlayerConfigEntity
    private let presenter: UIViewController
    private let audioPlaylistViewRouter: any AudioPlaylistViewRouting
    
    private(set) var nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate?
    private(set) var fileLinkActionViewControllerDelegate: FileLinkActionViewControllerDelegate?
    
    var baseViewController: UIViewController?
    
    init(configEntity: AudioPlayerConfigEntity, presenter: UIViewController, audioPlaylistViewRouter: some AudioPlaylistViewRouting) {
        self.configEntity = configEntity
        self.presenter = presenter
        self.audioPlaylistViewRouter = audioPlaylistViewRouter
        super.init()
    }
    
    func build() -> UIViewController {
        guard let vc = baseViewController else { return UIViewController() }
        
        switch configEntity.nodeOriginType {
        case .folderLink, .chat:
            nodeActionViewControllerDelegate = NodeActionViewControllerGenericDelegate(
                viewController: vc,
                isNodeFromFolderLink: configEntity.isFolderLink,
                messageId: configEntity.messageId,
                chatId: configEntity.chatId
            )
        case .fileLink:
            fileLinkActionViewControllerDelegate = FileLinkActionViewControllerDelegate(
                link: configEntity.fileLink ?? "",
                viewController: vc
            )
        case .unknown:
            break
        }
        
        return configEntity.fileLink != nil ? MEGANavigationController(rootViewController: vc) : vc
    }
    
    @objc func start() {
        presenter.present(build(), animated: true, completion: nil)
    }
    
    // MARK: - UI Actions
    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
    
    func goToPlaylist() {
        audioPlaylistViewRouter.start()
    }
    
    func showMiniPlayer(node: MEGANode?, shouldReload: Bool) {
        configEntity.playerHandler.initMiniPlayer(node: node, fileLink: configEntity.fileLink, filePaths: configEntity.relatedFiles, isFolderLink: configEntity.isFolderLink, presenter: presenter, shouldReloadPlayerInfo: shouldReload, shouldResetPlayer: false)
    }
    
    func showMiniPlayer(file: String, shouldReload: Bool) {
        configEntity.playerHandler.initMiniPlayer(node: nil, fileLink: file, filePaths: configEntity.relatedFiles, isFolderLink: configEntity.isFolderLink, presenter: presenter, shouldReloadPlayerInfo: shouldReload, shouldResetPlayer: false)
    }
    
    func importNode(_ node: MEGANode) {
        fileLinkActionViewControllerDelegate?.importNode(node)
    }
    
    func share(sender: UIBarButtonItem?) {
        fileLinkActionViewControllerDelegate?.shareLink(sender: sender)
    }
    
    func sendToChat() {
        fileLinkActionViewControllerDelegate?.sendToChat()
    }
    
    func showAction(for node: MEGANode, sender: Any) {
        let displayMode: DisplayMode = node.mnz_isInRubbishBin() ? .rubbishBin : .cloudDrive
        let backupsUC = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let isBackupNode = backupsUC.isBackupNode(node.toNodeEntity())
        let nodeActionViewController = NodeActionViewController(
            node: node,
            delegate: AudioPlayerViewRouterNodeActionAdapter(
                configEntity: configEntity,
                nodeActionViewControllerDelegate: nodeActionViewControllerDelegate,
                fileLinkActionViewControllerDelegate: fileLinkActionViewControllerDelegate
            ),
            displayMode: displayMode,
            isInVersionsView: isPlayingFromVersionView(),
            isBackupNode: isBackupNode,
            sender: sender)
        
        baseViewController?.present(nodeActionViewController, animated: true, completion: nil)
    }
    
    private func isPlayingFromVersionView() -> Bool {
        presenter.isKind(of: NodeVersionsViewController.self)
    }
}
