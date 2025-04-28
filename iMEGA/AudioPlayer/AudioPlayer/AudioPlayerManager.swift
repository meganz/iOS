import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

@objc final class AudioPlayerManager: NSObject, AudioPlayerHandlerProtocol {
    @objc static var shared = AudioPlayerManager()
    
    private var player: AudioPlayer?
    private var fullScreenPlayerRouter: AudioPlayerViewRouter?
    private var miniPlayerRouter: MiniPlayerViewRouter?
    private var miniPlayerVC: MiniPlayerViewController?
    private var miniPlayerHandlerListenerManager = ListenerManager<any AudioMiniPlayerHandlerProtocol>()
    private var nodeInfoUseCase: (any NodeInfoUseCaseProtocol)?
    private let playbackContinuationUseCase: any PlaybackContinuationUseCaseProtocol =
        DIContainer.playbackContinuationUseCase
    private let audioSessionUseCase = AudioSessionUseCase(audioSessionRepository: AudioSessionRepository(audioSession: AVAudioSession()))
    private var shouldRemovePlayerInstance: Bool = false
    
    override private init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(closePlayer), name: Notification.Name.MEGALogout, object: nil)
    }
    
    func currentPlayer() -> AudioPlayer? {
        player
    }
    
    func isPlayerDefined() -> Bool {
        player != nil
    }
    
    func isPlayerEmpty() -> Bool {
        player?.tracks.isEmpty == true
    }
    
    func isPlayerPlaying() -> Bool {
        player?.isPlaying ?? false
    }
    
    func isPlayerPaused() -> Bool {
        player?.isPaused ?? false
    }
    
    func isPlayerAlive() -> Bool {
        player?.isAlive ?? false
    }
    
    func isShuffleEnabled() -> Bool {
        player?.isShuffleMode() ?? false
    }
    
    func autoPlay(enable: Bool) {
        player?.isAutoPlayEnabled = enable
    }
    
    func currentRepeatMode() -> RepeatMode {
        guard let player else { return .none }
        
        if player.isRepeatOneMode() {
            return .repeatOne
        } else if player.isRepeatAllMode() {
            return .loop
        } else {
            return .none
        }
    }
    
    func currentSpeedMode() -> SpeedMode {
        switch player?.rate {
        case 0.5: return SpeedMode.half
        case 1.0: return SpeedMode.normal
        case 1.5: return SpeedMode.oneAndAHalf
        case 2.0: return SpeedMode.double
        default: return SpeedMode.normal
        }
    }
    
    @objc func isPlayingNode(_ node: MEGANode) -> Bool {
        guard let currentNode = player?.currentNode,
                isPlayerAlive() else {
            return false
        }
        return node == currentNode
    }
    
    func setCurrent(
        player: AudioPlayer?,
        autoPlayEnabled: Bool,
        tracks: [AudioPlayerItem]
    ) {
        if self.player != nil {
            player?.close { [weak self] in
                MEGALogDebug("[AudioPlayer] closing current player before assign new instance")
                self?.player = nil
                self?.configure(player: player, autoPlayEnabled: autoPlayEnabled, tracks: tracks)
            }
        } else {
            configure(player: player, autoPlayEnabled: autoPlayEnabled, tracks: tracks)
        }
    }
    
    private func configure(
        player: AudioPlayer?,
        autoPlayEnabled: Bool,
        tracks: [AudioPlayerItem]
    ) {
        self.player = player
        self.player?.isAutoPlayEnabled = autoPlayEnabled
        self.player?.add(tracks: tracks)
    }
    
    func addPlayer(listener: any AudioPlayerObserversProtocol) {
        if !isPlayerListened(by: listener) {
            player?.add(listener: listener)
        }
    }
    
    func removePlayer(listener: any AudioPlayerObserversProtocol) {
        player?.remove(listener: listener)
    }
    
    private func isPlayerListened(by listener: any AudioPlayerObserversProtocol) -> Bool {
        guard let listeners = player?.observersListenerManager.listeners else {
            return false
        }
        return listeners.contains { $0 === listener }
    }
    
    func addPlayer(tracks: [AudioPlayerItem]) {
        playbackStoppedForCurrentItem()
        player?.add(tracks: tracks)
    }
    
    func move(item: AudioPlayerItem, to position: IndexPath, direction: MovementDirection) {
        player?.move(of: item, to: position, direction: direction)
    }
    
    func delete(items: [AudioPlayerItem]) {
        player?.deletePlaylist(items: items)
    }
    
    func playerProgressCompleted(percentage: Float) {
        player?.setProgressCompleted(percentage)
    }
    
    func playerProgressDragEventBegan() {
        player?.progressDragEventBegan()
    }
    
    func playerProgressDragEventEnded() {
        player?.progressDragEventEnded()
    }
    
    func playerShuffle(active: Bool) {
        player?.shuffle(active)
    }
    
    func goBackward() {
        player?.rewind(direction: .backward)
    }
    
    func playPrevious() {
        playbackStoppedForCurrentItem()
        player?.blockAudioPlayerInteraction()
        player?.playPrevious { [weak self] in
            self?.player?.unblockAudioPlayerInteraction()
        }
    }
    
    func playerTogglePlay() {
        player?.resetAudioSessionCategoryIfNeeded()
        checkIfCallExist(then: player?.togglePlay)
    }
    
    private func checkIfCallExist(then clousure: (() -> Void)?) {
        if MEGAChatSdk.shared.mnz_existsActiveCall {
            Helper.cannotPlayContentDuringACallAlert()
        } else {
            clousure?()
        }
    }
    
    func playerPause() {
        player?.resetAudioSessionCategoryIfNeeded()
        checkIfCallExist(then: player?.pause)
    }
    
    func playerPlay() {
        player?.resetAudioSessionCategoryIfNeeded()
        checkIfCallExist(then: player?.play)
    }
    
    func playerResumePlayback(from timeInterval: TimeInterval) {
        playerPause()
        player?.setProgressCompleted(timeInterval) { [weak self] in
            self?.playerPlay()
        }
    }
    
    func playNext() {
        playbackStoppedForCurrentItem()
        player?.blockAudioPlayerInteraction()
        player?.playNext { [weak self] in
            self?.player?.unblockAudioPlayerInteraction()
        }
    }
    
    func goForward() {
        player?.rewind(direction: .forward)
    }
    
    func play(item: AudioPlayerItem) {
        playbackStoppedForCurrentItem()
        player?.blockAudioPlayerInteraction()
        player?.play(item: item) { [weak self] in
            self?.player?.unblockAudioPlayerInteraction()
        }
    }
    
    func playerRepeatAll(active: Bool) {
        player?.repeatAll(active)
    }
    
    func playerRepeatOne(active: Bool) {
        player?.repeatOne(active)
    }
    
    func playerRepeatDisabled() {
        player?.repeatAll(false)
        player?.repeatOne(false)
    }
    
    func changePlayer(speed: SpeedMode) {
        switch speed {
        case .normal:
            player?.rate = 1.0
        case .oneAndAHalf:
            player?.rate = 1.5
        case .double:
            player?.rate = 2.0
        case .half:
            player?.rate = 0.5
        }
    }
    
    func refreshCurrentItemState() {
        player?.refreshCurrentItemState()
    }
    
    func playerCurrentItem() -> AudioPlayerItem? {
        player?.currentItem()
    }
    
    func playerCurrentItemTime() -> TimeInterval {
        player?.playerCurrentTime() ?? 0.0
    }
    
    func playerQueueItems() -> [AudioPlayerItem]? {
        player?.queueItems()
    }
    
    func playerPlaylistItems() -> [AudioPlayerItem]? {
        player?.tracks
    }
    
    func playerTracksContains(url: URL) -> Bool {
        player?.playerTracksContains(url: url) ?? false
    }
    
    @MainActor
    func initFullScreenPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController, messageId: HandleEntity, chatId: HandleEntity, isFromSharedItem: Bool, allNodes: [MEGANode]?) {
        let configEntity = AudioPlayerConfigEntity(node: node, isFolderLink: isFolderLink, fileLink: fileLink, messageId: messageId, chatId: chatId, relatedFiles: filePaths, allNodes: allNodes, playerHandler: self, isFromSharedItem: isFromSharedItem)
        
        let playlistRouter = AudioPlaylistViewRouter(configEntity: AudioPlayerConfigEntity(parentNode: configEntity.node?.parent, playerHandler: configEntity.playerHandler, isFromSharedItem: isFromSharedItem), presenter: presenter)
        
        let audioPlayerRouter = AudioPlayerViewRouter(
            configEntity: configEntity,
            presenter: presenter,
            audioPlaylistViewRouter: playlistRouter
        )
        
        guard let vc = makeAudioPlayerViewController(configEntity: configEntity, router: audioPlayerRouter) else { return }
        audioPlayerRouter.baseViewController = vc
        playlistRouter.setPresenter(audioPlayerRouter.baseViewController)
        
        audioPlayerRouter.start()
        
        fullScreenPlayerRouter = audioPlayerRouter
    }
    
    @MainActor
    private func makeAudioPlayerViewController(configEntity: AudioPlayerConfigEntity, router: some AudioPlayerViewRouting) -> AudioPlayerViewController? {
        guard let vc = UIStoryboard(name: "AudioPlayer", bundle: nil).instantiateViewController(
            identifier: "AudioPlayerViewControllerID",
            creator: { coder in
                let makeViewModel: () -> AudioPlayerViewModel = {
                    let playbackContinuationUC = DIContainer.playbackContinuationUseCase
                    let audioPlayerUC = AudioPlayerUseCase(repository: AudioPlayerRepository(sdk: .shared))
                    let accountUC = AccountUseCase(repository: AccountRepository.newRepo)
                    let networkMonitorUC = NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo)
                    let tracker = DIContainer.tracker
                    let offlineInfoUC = (configEntity.playerType == .offline) ? OfflineFileInfoUseCase(offlineInfoRepository: OfflineInfoRepository()) : nil
                    let nodeInfoUC = (configEntity.playerType != .offline) ? NodeInfoUseCase(nodeInfoRepository: NodeInfoRepository()) : nil
                    let streamingInfoUC = (configEntity.playerType != .offline) ? StreamingInfoUseCase(streamingInfoRepository: StreamingInfoRepository()) : nil
                    
                    return AudioPlayerViewModel(
                        configEntity: configEntity,
                        router: router,
                        nodeInfoUseCase: nodeInfoUC,
                        streamingInfoUseCase: streamingInfoUC,
                        offlineInfoUseCase: offlineInfoUC,
                        playbackContinuationUseCase: playbackContinuationUC,
                        audioPlayerUseCase: audioPlayerUC,
                        accountUseCase: accountUC,
                        networkMonitorUseCase: networkMonitorUC,
                        tracker: tracker
                    )
            }
            
            return AudioPlayerViewController(coder: coder, viewModel: makeViewModel())
        }) as? AudioPlayerViewController else {
            return nil
        }
        
        return vc
    }
    
    @MainActor
    func initMiniPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController, shouldReloadPlayerInfo: Bool, shouldResetPlayer: Bool, isFromSharedItem: Bool) {
        if shouldReloadPlayerInfo {
            if shouldResetPlayer { folderSDKLogoutIfNeeded() }
            
            guard player != nil else { return }
            
            let allNodes = currentPlayer()?.tracks.compactMap(\.node)
            miniPlayerRouter = MiniPlayerViewRouter(configEntity: AudioPlayerConfigEntity(node: node, isFolderLink: isFolderLink, fileLink: fileLink, relatedFiles: filePaths, allNodes: allNodes, playerHandler: self, shouldResetPlayer: shouldResetPlayer, isFromSharedItem: isFromSharedItem), presenter: presenter)
            
            miniPlayerVC = nil
            
            showMiniPlayer()
        }
        
        guard (presenter as? any AudioPlayerPresenterProtocol) == nil else {
            return
        }
        
        miniPlayerHandlerListenerManager.notify { $0.hideMiniPlayer() }
    }
    
    func closePlayer() {
        playbackStoppedForCurrentItem()
        player?.close { [weak self] in
            self?.audioSessionUseCase.configureCallAudioSession()
            self?.clearMiniPlayerResources()
        }
        
        shouldRemovePlayerInstance = true
        
        miniPlayerHandlerListenerManager.notify { $0.closeMiniPlayer() }
        
        NotificationCenter.default.post(name: NSNotification.Name.MEGAAudioPlayerShouldUpdateContainer, object: nil)
    }
    
    private func clearMiniPlayerResources() {
        miniPlayerVC = nil
        miniPlayerRouter = nil
    }
    
    @MainActor
    func dismissFullScreenPlayer() async {
        guard let fullScreenPlayerRouter else { return }
        
        await withCheckedContinuation { continuation in
            fullScreenPlayerRouter.dismiss { [weak self] in
                self?.fullScreenPlayerRouter = nil
                continuation.resume()
            }
        }
    }
    
    func playerHidden(_ hidden: Bool, presenter: UIViewController) {
        guard let presenter = presenter as? (any AudioPlayerPresenterProtocol) else { return }
        
        notifyDelegatesToShowHideMiniPlayer(hidden)
        
        refreshContentOffset(presenter: presenter, isHidden: hidden)
    }
    
    func refreshContentOffset(presenter: any AudioPlayerPresenterProtocol, isHidden: Bool) {
        if isHidden {
            presenter.updateContentView(0)
            
            cleanupPlayerInstance()
        } else {
            let height = miniPlayerHandlerListenerManager.listeners.last?.currentContainerHeight() ?? 0
            presenter.updateContentView(height)
        }
    }
    
    func cleanupPlayerInstance() {
        if shouldRemovePlayerInstance {
            player = nil
            shouldRemovePlayerInstance = false
        }
    }
    
    private func notifyDelegatesToShowHideMiniPlayer(_ hidden: Bool) {
        if hidden {
            miniPlayerHandlerListenerManager.notify {
                $0.hideMiniPlayer()
            }
        } else {
            miniPlayerHandlerListenerManager.notify {
                $0.showMiniPlayer()
            }
        }
    }
    
    @MainActor
    func updateMiniPlayerPresenter(_ presenter: any AudioPlayerPresenterProtocol) {
        miniPlayerRouter?.updatePresenter(presenter)
    }

    func addMiniPlayerHandler(_ handler: any AudioMiniPlayerHandlerProtocol) {
        miniPlayerHandlerListenerManager.add(handler)
    }
    
    func removeMiniPlayerHandler(_ handler: any AudioMiniPlayerHandlerProtocol) {
        miniPlayerHandlerListenerManager.remove(handler)
        handler.resetMiniPlayerContainer()
    }
    
    func presentMiniPlayer(_ viewController: UIViewController) {
        miniPlayerVC = viewController as? MiniPlayerViewController
        miniPlayerHandlerListenerManager.listeners.last?.presentMiniPlayer(viewController)
    }
    
    func showMiniPlayer() {
        guard let miniPlayerVC else {
            miniPlayerRouter?.start()
            return
        }
        let currentMiniPlayerHandler = miniPlayerHandlerListenerManager.listeners.last
        if currentMiniPlayerHandler?.containsMiniPlayerInstance() == true {
            currentMiniPlayerHandler?.showMiniPlayer()
        } else {
            currentMiniPlayerHandler?.presentMiniPlayer(miniPlayerVC)
        }
    }
    
    func audioInterruptionDidStart() {
        NotificationCenter.default.post(name: Notification.Name.MEGAAudioPlayerInterruption,
                                        object: nil,
                                        userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue])
    }
    
    func audioInterruptionDidEndNeedToResume(_ resume: Bool) {
        let userInfo = resume ? [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                                 AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue] :
                                [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue]
        
        NotificationCenter.default.post(name: Notification.Name.MEGAAudioPlayerInterruption,
                                        object: nil,
                                        userInfo: userInfo)
    }
    
    func remoteCommandEnabled(_ enabled: Bool) {
        enabled ? player?.enableRemoteCommands() : player?.disableRemoteCommands()
    }
    
    func resetAudioPlayerConfiguration() {
        player?.resetAudioPlayerConfiguration()
    }
    
    func resetCurrentItem(shouldResetPlayback: Bool) {
        player?.resetCurrentItem()
    }
    
    @MainActor
    private func isFolderSDKLogoutRequired() -> Bool {
        guard let miniPlayerRouter = miniPlayerRouter else { return false }
        return miniPlayerRouter.isFolderSDKLogoutRequired()
    }
    
    @MainActor
    private func folderSDKLogoutIfNeeded() {
        if isFolderSDKLogoutRequired() {
            if nodeInfoUseCase == nil {
                nodeInfoUseCase = NodeInfoUseCase()
            }
            nodeInfoUseCase?.folderLinkLogout()
            miniPlayerRouter?.folderSDKLogout(required: false)
        }
    }
    
    @objc func playbackStoppedForCurrentItem() {
        guard let fingerprint = playerCurrentItem()?.node?.fingerprint else { return }
        
        playbackContinuationUseCase.playbackStopped(
            for: fingerprint,
            on: playerCurrentItemTime(),
            outOf: player?.duration ?? 0.0
        )
    }
    
    func resettingAudioPlayer(shouldResetPlayback: Bool) {
        player?.isAudioPlayerBeingReset = true
        player?.resettingPlayback = shouldResetPlayback
    }
}
