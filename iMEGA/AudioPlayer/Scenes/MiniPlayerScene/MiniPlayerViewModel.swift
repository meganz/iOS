import Combine
import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAFoundation

enum MiniPlayerAction: ActionType {
    case onViewDidLoad
    case onPlayPause
    case playItem(AudioPlayerItem)
    case onClose
    case showPlayer(MEGANode?, String?)
    case scrollToCurrentItem
    case refresh(AudioPlayerConfigEntity)
}

@MainActor
protocol MiniPlayerViewRouting: AnyObject, Routing {
    func dismiss()
    func showPlayer(node: MEGANode?, filePath: String?)
    func isAFolderLinkPresenter() -> Bool
    func showTermsOfServiceViolationAlert()
}

@MainActor
final class MiniPlayerViewModel: ViewModelType {
    enum Command: CommandType, Equatable, Sendable {
        case reloadPlayerStatus(percentage: Float, isPlaying: Bool)
        case initTracks(currentItem: AudioPlayerItem, queue: [AudioPlayerItem]?, loopMode: Bool)
        case change(currentItem: AudioPlayerItem, indexPath: IndexPath)
        case reload(item: AudioPlayerItem)
        case showLoading(_ show: Bool)
        case enableUserInteraction(_ enable: Bool)
        case scrollToItem(indexPath: IndexPath)
    }
    
    // MARK: - Private properties
    private var configEntity: AudioPlayerConfigEntity
    private let playerHandler: any AudioPlayerHandlerProtocol
    private var shouldInitializePlayer: Bool
    private weak var router: (any MiniPlayerViewRouting)?
    private let nodeInfoUseCase: any NodeInfoUseCaseProtocol
    private let streamingInfoUseCase: any StreamingInfoUseCaseProtocol
    private let offlineInfoUseCase: any OfflineFileInfoUseCaseProtocol
    private let playbackContinuationUseCase: any PlaybackContinuationUseCaseProtocol
    private let audioPlayerUseCase: any AudioPlayerUseCaseProtocol
    private var shouldRegisterDelegate: Bool = true
    
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(configEntity: AudioPlayerConfigEntity,
         playerHandler: some AudioPlayerHandlerProtocol,
         router: some MiniPlayerViewRouting,
         nodeInfoUseCase: some NodeInfoUseCaseProtocol,
         streamingInfoUseCase: some StreamingInfoUseCaseProtocol,
         offlineInfoUseCase: some OfflineFileInfoUseCaseProtocol,
         playbackContinuationUseCase: some PlaybackContinuationUseCaseProtocol,
         audioPlayerUseCase: some AudioPlayerUseCaseProtocol
    ) {
        self.configEntity = configEntity
        self.playerHandler = playerHandler
        self.router = router
        self.nodeInfoUseCase = nodeInfoUseCase
        self.streamingInfoUseCase = streamingInfoUseCase
        self.offlineInfoUseCase = offlineInfoUseCase
        self.playbackContinuationUseCase = playbackContinuationUseCase
        self.audioPlayerUseCase = audioPlayerUseCase
        self.shouldInitializePlayer = configEntity.shouldResetPlayer
        
        self.setupUpdateItemSubscription()
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: MiniPlayerAction) {
        switch action {
        case .onViewDidLoad:
            initializeMiniPlayer()
        case .onPlayPause:
            playerHandler.playerTogglePlay()
        case .playItem(let item):
            if playerHandler.currentRepeatMode() == .repeatOne {
                playerHandler.playerRepeatAll(active: true)
            }
            playerHandler.play(item: item)
        case .onClose:
            closeMiniPlayer()
        case .showPlayer(let node, let filePath):
            showFullScreenPlayer(node, path: filePath)
        case .scrollToCurrentItem:
            if let currentItem = playerHandler.playerCurrentItem(),
               let queue = playerHandler.playerPlaylistItems(),
               let index = queue.firstIndex(of: currentItem) {
                let indexPath = IndexPath(row: index, section: 0)
                invokeCommand?(.scrollToItem(indexPath: indexPath))
            }
        case .refresh(let newConfig):
            updateConfig(to: newConfig)
        }
    }
    
    private func invoke(command: Command) {
        invokeCommand?(command)
    }
    
    private func isConfigNodeTakenDown() async throws -> Bool {
        guard let node = configEntity.node else { return true }
        return try await nodeInfoUseCase.isTakenDown(node: node, isFolderLink: configEntity.isFolderLink)
    }
    
    private func initializeMiniPlayer() {
        Task { [weak self] in
            guard let self, configEntity.node != nil else { return }
            let isTakenDown = try await isConfigNodeTakenDown()
            if isTakenDown {
                router?.showTermsOfServiceViolationAlert()
                return
            }
            
            if shouldRegisterDelegate {
                await audioPlayerUseCase.registerMEGADelegate()
                shouldRegisterDelegate = false
            }
        }
        invoke(command: .showLoading(shouldInitializePlayer))
        determinePlayerSetupOnViewDidLoad()
    }
    
    private func determinePlayerSetupOnViewDidLoad() {
        guard shouldInitializePlayer else {
            configurePlayer()
            playerHandler.refreshCurrentItemState()
            return
        }
        
        playerHandler.resettingAudioPlayer(shouldResetPlayback: configEntity.playerType != .fileLink)
        
        Task {
            await self.preparePlayer(isOffline: self.configEntity.playerType == .offline)
        }
    }
    
    private nonisolated func preparePlayer(isOffline: Bool) async {
        guard isOffline else {
            await preparePlayerForNonOfflinePlayerType()
            return
        }
        await preparePlayerForOfflinePlayerType()
    }
    
    private func dismiss() {
        router?.dismiss()
    }
    
    private func preparePlayerForOfflinePlayerType() async {
        guard let offlineFilePaths = configEntity.relatedFiles else {
            dismiss()
            return
        }
        
        guard
            let currentItem = playerHandler.playerCurrentItem(),
            currentItem.url.path == configEntity.fileLink,
            currentItem.node == configEntity.node
        else {
            await initialize(with: offlineFilePaths)
            return
        }
        configurePlayer()
        playerHandler.resetCurrentItem(shouldResetPlayback: configEntity.playerType != .fileLink)
    }
    
    private func preparePlayerForNonOfflinePlayerType() async {
        guard let node = configEntity.node else {
            dismiss()
            return
        }
        
        if !streamingInfoUseCase.isLocalHTTPProxyServerRunning() {
            streamingInfoUseCase.startServer()
        }
        
        guard
            let currentItem = playerHandler.playerCurrentItem(),
            currentItem.node == node
        else {
            await initialize(with: node)
            return
        }
        configurePlayer()
        playerHandler.resetCurrentItem(shouldResetPlayback: configEntity.playerType != .fileLink)
    }
    
    private func configurePlayer() {
        playerHandler.configurePlayer(listener: self)
        
        guard !playerHandler.isPlayerEmpty(), let currentItem = playerHandler.playerCurrentItem() else {
            router?.dismiss()
            return
        }
        invokeCommand?(.initTracks(currentItem: currentItem, queue: playerHandler.playerPlaylistItems(), loopMode: playerHandler.currentRepeatMode() == .loop))
    }
    
    // MARK: - Node Init
    
    private nonisolated func initialize(with node: MEGANode) async {
        if await configEntity.isFileLink {
            guard let track = streamingInfoUseCase.info(from: node) else {
                await dismiss()
                return
            }
            await initialize(tracks: [track], currentTrack: track)
        } else {
            guard let children = await configEntity.isFolderLink ? nodeInfoUseCase.folderChildrenInfo(fromParentHandle: node.parentHandle) :
                                                nodeInfoUseCase.childrenInfo(fromParentHandle: node.parentHandle),
                  let currentTrack = await children.async.first(where: { await $0.node?.handle == node.handle }) else {
                
                guard let track = streamingInfoUseCase.info(from: node) else {
                    await dismiss()
                    return
                }
                await initialize(tracks: [track], currentTrack: track)
                return
            }
            await initialize(tracks: children, currentTrack: currentTrack)
        }
    }
    
    // MARK: - Offline Files Init
    
    private nonisolated func initialize(with offlineFilePaths: [String]) async {
        guard
            let files = offlineInfoUseCase.info(from: offlineFilePaths),
            let currentFilePath = await configEntity.fileLink,
            let currentTrack = await files.async.first(where: { await $0.url.path == currentFilePath })
        else {
            await dismiss()
            return
        }
        await initialize(tracks: files, currentTrack: currentTrack)
    }
    
    // MARK: - Private functions
    
    private func initialize(tracks: [AudioPlayerItem], currentTrack: AudioPlayerItem) {
        let mutableTracks = shift(tracks: tracks, startItem: currentTrack)
        resetConfigurationIfNeeded(nextCurrentTrack: currentTrack)
        playerHandler.addPlayer(tracks: mutableTracks)
        configurePlayer()
    }

    private func shift(tracks: [AudioPlayerItem], startItem: AudioPlayerItem) -> [AudioPlayerItem] {
        guard tracks.contains(startItem) else { return tracks }
        return tracks.shifted(tracks.firstIndex(of: startItem) ?? 0)
    }
    
    private func resetConfigurationIfNeeded(nextCurrentTrack: AudioPlayerItem) {
        switch configEntity.playerType {
        case .default:
            if let currentNode = playerHandler.playerCurrentItem()?.node {
                guard let nextCurrentNode = nextCurrentTrack.node,
                      nextCurrentNode.parentHandle != currentNode.parentHandle else { return }
            }
            
        case .folderLink:
            guard !playerHandler.playerTracksContains(url: nextCurrentTrack.url) else { return }
            
        case .offline:
            let nextCurrentItemDirectoryURL = nextCurrentTrack.url.deletingLastPathComponent()
            guard let currentItemDirectoryURL = playerHandler.playerCurrentItem()?.url.deletingLastPathComponent(),
                  nextCurrentItemDirectoryURL != currentItemDirectoryURL else { return }
            
        default:
            break
        }
        
        playerHandler.resetAudioPlayerConfiguration()
    }
    
    private func showFullScreenPlayer(_ node: MEGANode?, path: String?) {
        playerHandler.removePlayer(listener: self)
        switch configEntity.playerType {
        case .`default`: router?.showPlayer(node: node, filePath: nil)
        case .folderLink, .fileLink, .offline: router?.showPlayer(node: node, filePath: configEntity.playerType == .fileLink ? configEntity.fileLink : path)
        }
    }
    
    private func closeMiniPlayer() {
        playerHandler.removePlayer(listener: self)
        
        streamingInfoUseCase.stopServer()
        if configEntity.isFolderLink,
            let router,
            !router.isAFolderLinkPresenter() {
            nodeInfoUseCase.folderLinkLogout()
        }
        router?.dismiss()
        
        Task { [audioPlayerUseCase] in
            await audioPlayerUseCase.unregisterMEGADelegate()
        }
    }
    
    private func updateConfig(to newConfig: AudioPlayerConfigEntity) {
        configEntity = newConfig
        shouldInitializePlayer = configEntity.shouldResetPlayer
        initializeMiniPlayer()
    }
}

extension MiniPlayerViewModel: AudioPlayerObserversProtocol {
    nonisolated func audio(player: AVQueuePlayer, showLoading: Bool) {
        Task { @MainActor in
            invokeCommand?(.showLoading(showLoading))
        }
    }
    
    nonisolated func audio(player: AVQueuePlayer, currentTime: Double, remainingTime: Double, percentageCompleted: Float, isPlaying: Bool) {
        Task { @MainActor in
            invokeCommand?(.reloadPlayerStatus(percentage: percentageCompleted, isPlaying: isPlaying))
        }
    }
    
    nonisolated func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, indexPath: IndexPath?) {
        Task { @MainActor in
            guard let currentItem = currentItem, let indexPath = indexPath else { return }
            invokeCommand?(.change(currentItem: currentItem, indexPath: indexPath))
        }
    }
    
    nonisolated func audio(player: AVQueuePlayer, reload item: AudioPlayerItem?) {
        Task { @MainActor in
            guard let currentItem = item else { return }
            invokeCommand?(.reload(item: currentItem))
        }
    }
    
    nonisolated func audioPlayerWillStartBlockingAction() {
        Task { @MainActor in
            invokeCommand?(.enableUserInteraction(false))
        }
    }
    
    nonisolated func audioPlayerDidFinishBlockingAction() {
        Task { @MainActor in
            invokeCommand?(.enableUserInteraction(true))
        }
    }
    
    nonisolated func audioDidStartPlayingItem(_ item: AudioPlayerItem?) {
        Task { @MainActor in
            guard let item, let fingerprint = item.node?.toNodeEntity().fingerprint else {
                return
            }
            
            switch playbackContinuationUseCase.status(for: fingerprint) {
            case .displayDialog(let playbackTime):
                playbackContinuationUseCase.setPreference(to: .resumePreviousSession)
                playerHandler.playerResumePlayback(from: playbackTime)
            case .resumeSession(let playbackTime):
                playerHandler.playerResumePlayback(from: playbackTime)
            case .startFromBeginning: break
            }
        }
    }
}

extension MiniPlayerViewModel {
    
    private func setupUpdateItemSubscription() {
        audioPlayerUseCase.reloadItemPublisher()
            .sink(receiveValue: { [weak self] nodes in
                self?.onNodesUpdate(nodes)
            })
            .store(in: &subscriptions)
    }
    
    private func onNodesUpdate(_ nodeList: [NodeEntity]) {
        guard
            nodeList.isNotEmpty,
            let updatedNode = nodeList.first,
            configEntity.allNodes?.contains(where: { $0.handle == updatedNode.handle }) == true
        else {
            return
        }
        
        refreshItem(updatedNode.handle)
    }
    
    private func refreshItem(_ nodeHandle: HandleEntity) {
        guard let node = nodeInfoUseCase.node(fromHandle: nodeHandle) else { return }
        
        playerHandler.currentPlayer()?.refreshTrack(with: node)
        refreshItemUI(nodeHandle: nodeHandle)
    }
    
    private func refreshItemUI(nodeHandle: HandleEntity) {
        guard let currentPlayer = playerHandler.currentPlayer(),
              let item = currentPlayer.tracks.first(where: { $0.node?.handle == nodeHandle }) else { return }
        
        invokeCommand?(.reload(item: item))
    }
}
