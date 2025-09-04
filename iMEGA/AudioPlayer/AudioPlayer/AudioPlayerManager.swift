import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

final class AudioPlayerManager: NSObject, AudioPlayerHandlerProtocol {
    static var shared = AudioPlayerManager()
    
    private var player: AudioPlayer?
    private var fullScreenPlayerRouter: AudioPlayerViewRouter?
    private var miniPlayerRouter: MiniPlayerViewRouter?
    /// Stores all registered mini-player handlers in a thread-safe array. Access is synchronized with `@Atomic`, and handlers are compared
    /// by identity using `ObjectIdentifier` to avoid duplicates. Handlers conforming to `AudioMiniPlayerHandlerProtocol` manage the
    /// presentation and behavior of the mini-player, such as showing or hiding it, updating its container height, or embedding the mini-player view.
    @Atomic private var miniPlayerHandlers: [any AudioMiniPlayerHandlerProtocol] = []
    private var nodeInfoUseCase: (any NodeInfoUseCaseProtocol)?
    private let playbackContinuationUseCase: any PlaybackContinuationUseCaseProtocol =
        DIContainer.playbackContinuationUseCase
    private let audioSessionUseCase = AudioSessionUseCase(audioSessionRepository: AudioSessionRepository(audioSession: AVAudioSession()))
    
    private let miniPlayerHeight: CGFloat = 56.0
    
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
    
    func isSingleItemPlaylist() -> Bool {
        player?.tracks.count == 1
    }
    
    func currentRepeatMode() -> RepeatMode {
        guard let player else { return .none }
        if player.isRepeatOneMode() { return .repeatOne }
        if player.isRepeatAllMode() { return .loop }
        return .none
    }
    
    func currentSpeedMode() -> SpeedMode {
        return switch player?.rate {
        case 0.5: .half
        case 1.0: .normal
        case 1.5: .oneAndAHalf
        case 2.0: .double
        default: .normal
        }
    }
    
    func isPlayingNode(_ node: MEGANode) -> Bool {
        guard let currentNode = player?.currentNode,
                isPlayerAlive() else {
            return false
        }
        return node == currentNode
    }
    
    func setCurrent(
        player: AudioPlayer?,
        tracks: [AudioPlayerItem],
        playerListener: any AudioPlayerObserversProtocol
    ) {
        if self.player != nil {
            self.player?.close { [weak self] in
                MEGALogDebug("[AudioPlayer] closing current player before assign new instance")
                self?.player = nil
                self?.configure(player: player, tracks: tracks, playerListener: playerListener)
            }
        } else {
            configure(player: player, tracks: tracks, playerListener: playerListener)
        }
    }
    
    private func configure(
        player: AudioPlayer?,
        tracks: [AudioPlayerItem],
        playerListener: any AudioPlayerObserversProtocol
    ) {
        self.player = player
        configurePlayer(listener: playerListener)
        self.player?.add(tracks: tracks)
    }
    
    func configurePlayer(listener: any AudioPlayerObserversProtocol) {
        if !isPlayerListened(by: listener) {
            player?.configure(listener: listener)
        }
    }
    
    func removePlayer(listener: any AudioPlayerObserversProtocol) {
        player?.remove(listener: listener)
    }
    
    private func isPlayerListened(by listener: any AudioPlayerObserversProtocol) -> Bool {
        guard let listeners = player?.observerSnapshot() else {
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
    
    func delete(items: [AudioPlayerItem]) async {
        await player?.deletePlaylist(items: items)
    }
    
    func playerProgressCompleted(percentage: Float) {
        player?.setProgressCompleted(percentage)
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
        let configEntity = AudioPlayerConfigEntity(
            node: node,
            isFolderLink: isFolderLink,
            fileLink: fileLink,
            messageId: messageId,
            chatId: chatId,
            relatedFiles: filePaths,
            allNodes: allNodes,
            isFromSharedItem: isFromSharedItem
        )
        
        let audioPlayerRouter = AudioPlayerViewRouter(
            configEntity: configEntity,
            presenter: presenter
        )
        audioPlayerRouter.start()
        fullScreenPlayerRouter = audioPlayerRouter
    }
    
    @MainActor
    func initMiniPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController, shouldReloadPlayerInfo: Bool, shouldResetPlayer: Bool, isFromSharedItem: Bool) {
        if shouldReloadPlayerInfo {
            if shouldResetPlayer { folderSDKLogoutIfNeeded() }
            
            guard player != nil else { return }
            
            let allNodes = currentPlayer()?.tracks.compactMap(\.node)
            let config = AudioPlayerConfigEntity(node: node, isFolderLink: isFolderLink, fileLink: fileLink, relatedFiles: filePaths, allNodes: allNodes, shouldResetPlayer: shouldResetPlayer, isFromSharedItem: isFromSharedItem)
            
            if miniPlayerRouter == nil {
                miniPlayerRouter = MiniPlayerViewRouter(
                    configEntity: config,
                    presenter: presenter
                )
                miniPlayerRouter?.start()
            } else {
                miniPlayerRouter?.refresh(with: config)
            }
        }
        
        guard (presenter as? any AudioPlayerPresenterProtocol) == nil else {
            return
        }
        
        notifyMiniPlayerHandlers { $0.hideMiniPlayer() }
    }
    
    @objc func closePlayer() {
        playbackStoppedForCurrentItem()
        player?.close { [weak self] in
            self?.audioSessionUseCase.configureCallAudioSession()
            self?.clearMiniPlayerResources()
        }
        notifyMiniPlayerHandlers { $0.closeMiniPlayer() }
        
        NotificationCenter.default.post(name: NSNotification.Name.MEGAAudioPlayerShouldUpdateContainer, object: nil)
        
        player = nil
    }
    
    func clearMiniPlayerResources() {
        miniPlayerRouter = nil
    }
    
    func clearFullScreenPlayerResources() {
        fullScreenPlayerRouter = nil
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
        } else {
            let height = miniPlayerHandlers.last?.currentContainerHeight() ?? 0
            presenter.updateContentView(height)
        }
    }
    
    private func notifyDelegatesToShowHideMiniPlayer(_ hidden: Bool) {
        if hidden {
            miniPlayerHandlers.forEach {
                $0.hideMiniPlayer()
            }
        } else {
            miniPlayerHandlers.forEach {
                $0.showMiniPlayer()
            }
        }
    }
    
    @MainActor
    func updateMiniPlayerPresenter(_ presenter: any AudioPlayerPresenterProtocol) {
        miniPlayerRouter?.updatePresenter(presenter)
    }

    func addMiniPlayerHandler(_ handler: any AudioMiniPlayerHandlerProtocol) {
        $miniPlayerHandlers.mutate { arr in
            let exists = arr.contains { ObjectIdentifier($0) == ObjectIdentifier(handler) }
            if !exists { arr.append(handler) }
        }
    }
    
    func removeMiniPlayerHandler(_ handler: any AudioMiniPlayerHandlerProtocol) {
        $miniPlayerHandlers.mutate { arr in
            if let i = arr.firstIndex(where: { ObjectIdentifier($0) == ObjectIdentifier(handler) }) {
                arr.remove(at: i)
            }
        }
        handler.resetMiniPlayerContainer()
    }
    
    func notifyMiniPlayerHandlers(_ closure: (any AudioMiniPlayerHandlerProtocol) -> Void) {
        miniPlayerHandlers.forEach(closure)
    }
    
    func presentMiniPlayer(_ viewController: UIViewController) {
        miniPlayerHandlers.last?.presentMiniPlayer(viewController, height: miniPlayerHeight)
    }
    
    @MainActor
    func showMiniPlayer() {
        guard let miniPlayerRouter, let current = miniPlayerHandlers.last else { return }
        if current.containsMiniPlayerInstance() {
            current.showMiniPlayer()
        } else if let view = miniPlayerRouter.currentMiniPlayerView() {
            current.presentMiniPlayer(view, height: miniPlayerHeight)
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
        guard let miniPlayerRouter else { return false }
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
    
    func playbackStoppedForCurrentItem() {
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
