import Accounts
import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

@MainActor
final class AudioPlayerViewRouter: NSObject, AudioPlayerViewRouting {
    private let configEntity: AudioPlayerConfigEntity
    private let presenter: UIViewController
    private let tracker: any AnalyticsTracking
    
    private(set) var nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate?
    private(set) var fileLinkActionViewControllerDelegate: FileLinkActionViewControllerDelegate?
    private(set) var nodeAccessoryActionDelegate: (any NodeAccessoryActionDelegate)?
    
    weak var baseViewController: UIViewController?
    
    init(
        configEntity: AudioPlayerConfigEntity,
        presenter: UIViewController,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.configEntity = configEntity
        self.presenter = presenter
        self.tracker = tracker
        super.init()
    }
    
    deinit {
        MEGALogDebug("[AudioPlayer] deallocating AudioPlayerViewRouter instance")
    }
    
    @MainActor
    private func makeAudioPlayerViewController() -> AudioPlayerViewController? {
        let storyboard = UIStoryboard(name: "AudioPlayer", bundle: nil)
        guard let vc = storyboard.instantiateViewController(
            identifier: "AudioPlayerViewControllerID",
            creator: { coder in
                let viewModel = self.makeAudioPlayerViewModel()
                return AudioPlayerViewController(coder: coder, viewModel: viewModel)
            }
        ) as? AudioPlayerViewController else { return nil }
        return vc
    }

    private func makeAudioPlayerViewModel() -> AudioPlayerViewModel {
        let offlineInfoUC: OfflineFileInfoUseCase? = {
            guard configEntity.playerType == .offline else { return nil }
            return OfflineFileInfoUseCase(offlineInfoRepository: OfflineInfoRepository())
        }()

        let nodeInfoUC: NodeInfoUseCase? = {
            guard configEntity.playerType != .offline else { return nil }
            return NodeInfoUseCase(nodeInfoRepository: NodeInfoRepository())
        }()

        let streamingInfoUC: StreamingInfoUseCase? = {
            guard configEntity.playerType != .offline else { return nil }
            return StreamingInfoUseCase(streamingInfoRepository: StreamingInfoRepository())
        }()

        return AudioPlayerViewModel(
            configEntity: configEntity,
            router: self,
            nodeInfoUseCase: nodeInfoUC,
            streamingInfoUseCase: streamingInfoUC,
            offlineInfoUseCase: offlineInfoUC,
            playbackContinuationUseCase: DIContainer.playbackContinuationUseCase,
            audioPlayerUseCase: AudioPlayerUseCase(repository: AudioPlayerRepository(sdk: .shared)),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            tracker: DIContainer.tracker
        )
    }
    
    func build() -> UIViewController {
        guard let vc = makeAudioPlayerViewController() else { return UIViewController() }
        baseViewController = vc
        
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
        
        return configEntity.nodeOriginType == .fileLink ? MEGANavigationController(rootViewController: vc) : vc
    }
    
    @objc func start() {
        switch configEntity.nodeOriginType {
        case .fileLink:
            var audioPlayerViewController = build()
            if let adsSlotViewController = baseViewController as? (any AdsSlotViewControllerProtocol) {
                audioPlayerViewController = AdsSlotRouter(
                    adsSlotViewController: adsSlotViewController,
                    accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                    purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
                    nodeUseCase: NodeUseCase(
                        nodeDataRepository: NodeDataRepository.newRepo,
                        nodeValidationRepository: NodeValidationRepository.newRepo,
                        nodeRepository: NodeRepository.newRepo
                    ),
                    contentView: AdsViewWrapper(viewController: audioPlayerViewController),
                    publicLink: configEntity.fileLink,
                    isFolderLink: false
                ).build(adsFreeViewProPlanAction: {
                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    appDelegate?.showUpgradePlanPageFromAds()
                })
            }
            presenter.present(audioPlayerViewController, animated: true) {
                Task {
                    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                    await appDelegate.showAdMobConsentIfNeeded()
                }
            }
        default:
            presenter.present(build(), animated: true, completion: nil)
        }
    }
    
    // MARK: - UI Actions
    func dismiss(completion: @escaping () -> Void) {
        baseViewController?.dismiss(animated: true, completion: completion)
    }
    
    func goToPlaylist(parentNodeName: String) {
        guard let vc = baseViewController else { return }
        AudioPlaylistViewRouter(
            parentNodeName: parentNodeName,
            presenter: vc
        ).start()
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
