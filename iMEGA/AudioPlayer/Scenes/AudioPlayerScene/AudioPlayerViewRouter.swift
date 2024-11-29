import Accounts
import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation
import MEGASDKRepo

@MainActor
final class AudioPlayerViewRouter: NSObject, AudioPlayerViewRouting {
    private let configEntity: AudioPlayerConfigEntity
    private let presenter: UIViewController
    private let audioPlaylistViewRouter: any AudioPlaylistViewRouting
    private let tracker: any AnalyticsTracking
    
    private(set) var nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate?
    private(set) var fileLinkActionViewControllerDelegate: FileLinkActionViewControllerDelegate?
    private(set) var nodeAccessoryActionDelegate: (any NodeAccessoryActionDelegate)?
    
    weak var baseViewController: UIViewController?
    
    init(configEntity: AudioPlayerConfigEntity, presenter: UIViewController, audioPlaylistViewRouter: some AudioPlaylistViewRouting, tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.configEntity = configEntity
        self.presenter = presenter
        self.audioPlaylistViewRouter = audioPlaylistViewRouter
        self.tracker = tracker
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
                chatId: configEntity.chatId,
                moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: vc),
                nodeActionListener: nodeActionListener(tracker)
            )
            nodeAccessoryActionDelegate = DefaultNodeAccessoryActionDelegate()
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
        switch configEntity.nodeOriginType {
        case .fileLink:
            var audioPlayerViewController = build()
            if let adsSlotViewController = baseViewController as? (any AdsSlotViewControllerProtocol) {
                audioPlayerViewController = AdsSlotRouter(
                    adsSlotViewController: adsSlotViewController,
                    accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                    contentView: AdsViewWrapper(viewController: audioPlayerViewController)
                ).build()
            }
            presenter.present(audioPlayerViewController, animated: true, completion: nil)
        default:
            presenter.present(build(), animated: true, completion: nil)
        }
    }
    
    // MARK: - UI Actions
    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
    
    func goToPlaylist() {
        audioPlaylistViewRouter.start()
    }
    
    func showMiniPlayer(node: MEGANode?, shouldReload: Bool) {
        configEntity.playerHandler.initMiniPlayer(node: node, fileLink: configEntity.fileLink, filePaths: configEntity.relatedFiles, isFolderLink: configEntity.isFolderLink, presenter: presenter, shouldReloadPlayerInfo: shouldReload, shouldResetPlayer: false, isFromSharedItem: configEntity.isFromSharedItem)
    }
    
    func showMiniPlayer(file: String, shouldReload: Bool) {
        configEntity.playerHandler.initMiniPlayer(node: nil, fileLink: file, filePaths: configEntity.relatedFiles, isFolderLink: configEntity.isFolderLink, presenter: presenter, shouldReloadPlayerInfo: shouldReload, shouldResetPlayer: false, isFromSharedItem: configEntity.isFromSharedItem)
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
                fileLinkActionViewControllerDelegate: fileLinkActionViewControllerDelegate,
                audioPlayerViewController: baseViewController
            ),
            displayMode: displayMode,
            isInVersionsView: isPlayingFromVersionView(),
            isBackupNode: isBackupNode,
            isFromSharedItem: configEntity.isFromSharedItem,
            sender: sender)
        nodeActionViewController.accessoryActionDelegate = nodeAccessoryActionDelegate
        
        baseViewController?.present(nodeActionViewController, animated: true, completion: nil)
    }
    
    private func isPlayingFromVersionView() -> Bool {
        presenter.isKind(of: NodeVersionsViewController.self)
    }
    
    private func nodeActionListener(_ tracker: some AnalyticsTracking) -> (MegaNodeActionType?) -> Void {
        { action in
            switch action {
            case .hide:
                tracker.trackAnalyticsEvent(with: AudioPlayerHideNodeMenuItemEvent())
            default:
                break // we do not track other events here yet
            }
        }
    }
}
