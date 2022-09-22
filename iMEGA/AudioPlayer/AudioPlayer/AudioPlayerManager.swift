import Foundation

@objc final class AudioPlayerManager: NSObject, AudioPlayerHandlerProtocol {
    @objc static var shared = AudioPlayerManager()
    
    private var player: AudioPlayer?
    private var miniPlayerRouter: MiniPlayerViewRouter?
    private var miniPlayerVC: MiniPlayerViewController?
    private var miniPlayerHandlerListenerManager = ListenerManager<AudioMiniPlayerHandlerProtocol>()
    private var nodeInfoUseCase: NodeInfoUseCaseProtocol?
    
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
        if player?.isRepeatOneMode() ?? false { return .repeatOne }
        else if player?.isRepeatAllMode() ?? false { return .loop }
        return .none
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
    
    func setCurrent(player: AudioPlayer?, autoPlayEnabled: Bool, tracks: [AudioPlayerItem]) {
        if self.player != nil {
            CrashlyticsLogger.log("[AudioPlayer] current instance of the player \(String(describing: player)) need to be closed")
            player?.close() { [weak self] in
                MEGALogDebug("[AudioPlayer] closing current player before assign new instance")
                self?.player = nil
                CrashlyticsLogger.log("[AudioPlayer] player closed")
                self?.configure(player: player, autoPlayEnabled: autoPlayEnabled, tracks: tracks)
            }
        } else {
            configure(player: player, autoPlayEnabled: autoPlayEnabled, tracks: tracks)
        }
    }
    
    private func configure(player: AudioPlayer?, autoPlayEnabled: Bool, tracks: [AudioPlayerItem]) {
        CrashlyticsLogger.log("[AudioPlayer] new player being configured: (autoPlayEnabled: \(autoPlayEnabled), tracks: \(tracks)")
        self.player = player
        self.player?.isAutoPlayEnabled = autoPlayEnabled
        self.player?.add(tracks: tracks)
    }
    
    func addPlayer(listener: AudioPlayerObserversProtocol) {
        player?.add(listener: listener)
    }
    
    func removePlayer(listener: AudioPlayerObserversProtocol) {
        player?.remove(listener: listener)
    }
    
    func addPlayer(tracks: [AudioPlayerItem]) {
        CrashlyticsLogger.log("[AudioPlayer] adding new tracks: \(tracks)")
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
        player?.blockAudioPlayerInteraction()
        player?.playPrevious() { [weak self] in
            self?.player?.unblockAudioPlayerInteraction()
        }
    }
    
    func playerTogglePlay() {
        player?.resetAudioSessionCategoryIfNeeded()
        checkIfCallExist(then: player?.togglePlay)
    }
    
    private func checkIfCallExist(then clousure: (() -> Void)?) {
        if MEGASdkManager.sharedMEGAChatSdk().mnz_existsActiveCall {
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
    
    func playNext() {
        player?.blockAudioPlayerInteraction()
        player?.playNext() { [weak self] in
            self?.player?.unblockAudioPlayerInteraction()
        }
    }
    
    func goForward() {
        player?.rewind(direction: .forward)
    }
    
    func play(item: AudioPlayerItem) {
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
    
    func initFullScreenPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController) {
        AudioPlayerViewRouter(configEntity: AudioPlayerConfigEntity(node: node, isFolderLink: isFolderLink, fileLink: fileLink, relatedFiles: filePaths, playerHandler: self), presenter: presenter).start()
    }
    
    func initMiniPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController, shouldReloadPlayerInfo: Bool, shouldResetPlayer: Bool) {
        if shouldReloadPlayerInfo {
            if shouldResetPlayer { folderSDKLogoutIfNeeded() }
            
            guard player != nil else { return }
            
            miniPlayerRouter = MiniPlayerViewRouter(configEntity: AudioPlayerConfigEntity(node: node, isFolderLink: isFolderLink, fileLink: fileLink, relatedFiles: filePaths, playerHandler: self, shouldResetPlayer: shouldResetPlayer), presenter: presenter)
            
            miniPlayerVC = nil
            
            showMiniPlayer()
        }
        
        guard let delegate = presenter as? AudioPlayerPresenterProtocol else {
            miniPlayerHandlerListenerManager.notify{$0.hideMiniPlayer()}
            return
        }
        
        addDelegate(delegate)
    }
    
    func closePlayer() {
        player?.close() {
            AVAudioSession.sharedInstance().mnz_configureAVSessionForCall()
        }
        
        player?.updateContentViews()
        miniPlayerHandlerListenerManager.notify{$0.closeMiniPlayer()}
        
        NotificationCenter.default.post(name: NSNotification.Name.MEGAAudioPlayerShouldUpdateContainer, object: nil)
        
        miniPlayerVC = nil
        miniPlayerRouter = nil
        player = nil
    }
    
    func playerHidden(_ hidden: Bool, presenter: UIViewController) {
        guard presenter.conforms(to: AudioPlayerPresenterProtocol.self) else { return }
        
        if hidden {
            miniPlayerHandlerListenerManager.notify{$0.hideMiniPlayer()}
        } else {
            miniPlayerHandlerListenerManager.notify{$0.showMiniPlayer()}
        }
        
        player?.updateContentViews()
    }
    
    func addDelegate(_ delegate: AudioPlayerPresenterProtocol) {
        player?.add(presenterListener: delegate)
        
        guard let vc = delegate as? UIViewController else { return }
        playerHidden(!isPlayerAlive(), presenter: vc)
        miniPlayerRouter?.updatePresenter(vc)
    }
    
    func removeDelegate(_ delegate: AudioPlayerPresenterProtocol) {
        guard let vc = delegate as? UIViewController else { return }
        playerHidden(true, presenter: vc)
        
        player?.remove(presenterListener: delegate)
    }

    func addMiniPlayerHandler(_ handler: AudioMiniPlayerHandlerProtocol) {
        miniPlayerHandlerListenerManager.add(handler)
    }
    
    func removeMiniPlayerHandler(_ handler: AudioMiniPlayerHandlerProtocol) {
        miniPlayerHandlerListenerManager.remove(handler)
        handler.resetMiniPlayerContainer()
    }
    
    func presentMiniPlayer(_ viewController: UIViewController) {
        miniPlayerVC = viewController as? MiniPlayerViewController
        miniPlayerHandlerListenerManager.notify{$0.presentMiniPlayer(viewController)}
    }
    
    func showMiniPlayer() {
        guard let miniPlayerVC = miniPlayerVC else {
            miniPlayerRouter?.start()
            return
        }
        miniPlayerHandlerListenerManager.notify{$0.presentMiniPlayer(miniPlayerVC)}
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
    
    func resetCurrentItem() {
        player?.resetCurrentItem()
    }
    
    private func isFolderSDKLogoutRequired() -> Bool {
        guard let miniPlayerRouter = miniPlayerRouter else { return false }
        return miniPlayerRouter.isFolderSDKLogoutRequired()
    }
    
    private func folderSDKLogoutIfNeeded() {
        if isFolderSDKLogoutRequired() {
            if nodeInfoUseCase == nil {
                nodeInfoUseCase = NodeInfoUseCase()
            }
            nodeInfoUseCase?.folderLinkLogout()
            miniPlayerRouter?.folderSDKLogout(required: false)
        }
    }
}
