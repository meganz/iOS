import Foundation

@objc final class AudioPlayerManager: NSObject, AudioPlayerHandlerProtocol {
    
    @objc static var shared = AudioPlayerManager()
    
    private var player: AudioPlayer?
    private var miniPlayerRouter: MiniPlayerViewRouter?
    private var miniPlayerVC: MiniPlayerViewController?
    private var miniPlayerHandlerListenerManager = ListenerManager<AudioMiniPlayerHandlerProtocol>()
    
    func currentPlayer() -> AudioPlayer? {
        player
    }
    
    func isPlayerDefined() -> Bool {
        player != nil
    }
    
    func isPlayerEmpty() -> Bool {
        player?.tracks.count == 0
    }
    
    func isPlayerPlaying() -> Bool {
        player?.isPlaying ?? false
    }
    
    func isPlayerPaused() -> Bool {
        player?.isPaused ?? false
    }
    
    func isPlayerAlive() -> Bool {
        player?.isPlaying ?? false || player?.isPaused ?? false
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
    
    func setCurrent(player: AudioPlayer?, autoPlayEnabled: Bool) {
        self.player = player
        self.player?.isAutoPlayEnabled = autoPlayEnabled
    }
    
    func addPlayer(listener: AudioPlayerObserversProtocol) {
        player?.add(listener: listener)
    }
    
    func removePlayer(listener: AudioPlayerObserversProtocol) {
        player?.remove(listener: listener)
    }
    
    func addPlayer(tracks: [AudioPlayerItem]) {
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
    
    func playerShuffle(active: Bool) {
        player?.shuffle(active)
    }
    
    func playPrevious() {
        player?.blockAudioPlayerInteraction()
        player?.playPrevious() { [weak self] in
            self?.player?.unblockAudioPlayerInteraction()
        }
    }
    
    func playerTogglePlay() {
        player?.togglePlay()
    }
    
    func playerPause() {
        player?.pause()
    }
    
    func playerPlay() {
        player?.play()
    }
    
    func playNext() {
        player?.blockAudioPlayerInteraction()
        player?.playNext() { [weak self] in
            self?.player?.unblockAudioPlayerInteraction()
        }
    }
    
    func play(direction: MovementDirection) {
        player?.blockAudioPlayerInteraction()
        player?.play(direction) { [weak self] in
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
    
    func initFullScreenPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController) {
        if let node = node {
            AudioPlayerViewRouter(node: node, fileLink: fileLink, isFolderLink: isFolderLink, presenter: presenter, playerHandler: self).start()
        } else if let fileLink = fileLink {
            AudioPlayerViewRouter(selectedFile: fileLink, relatedFiles: filePaths, presenter: presenter, playerHandler: self).start()
        }
    }
    
    func initMiniPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController, shouldReloadPlayerInfo: Bool, shouldResetPlayer: Bool) {
        if shouldReloadPlayerInfo {
            guard player != nil else { return }
            
            miniPlayerRouter = shouldResetPlayer ?
                MiniPlayerViewRouter(node: node, fileLink: fileLink, relatedFiles: filePaths, isFolderLink: isFolderLink, presenter: presenter, playerHandler: self) :
                MiniPlayerViewRouter(fileLink: fileLink, relatedFiles: filePaths, isFolderLink: isFolderLink, presenter: presenter, playerHandler: self)
            
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
        player?.close()
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
    
    func showMiniPlayer() {
        if miniPlayerVC == nil {
            miniPlayerVC = miniPlayerRouter?.build() as? MiniPlayerViewController
        }
        guard let miniPlayerVC = miniPlayerVC else { return }
        
        miniPlayerHandlerListenerManager.notify{$0.initMiniPlayer(viewController: miniPlayerVC)}
    }
    
    func setAudioPlayerAudioSession() {
        player?.setAudioSession(active: true)
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
}
