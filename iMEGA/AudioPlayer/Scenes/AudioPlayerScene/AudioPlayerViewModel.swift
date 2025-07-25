import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAFoundation
import MEGAL10n

enum AudioPlayerAction: ActionType {
    
    /// Enum to represent the reasons for the dissapearance  of a view.
    enum ViewWillDisappearReason {
        /// User dismissal means the user initiated the dismissal of the screen (e.g., tapping the close button or swiping down to close the audio player view).
        case userInitiatedDismissal
        
        /// The view disappeared because another view was pushed over the current audio player view.
        case systemPushedAnotherView
    }
    
    case onViewDidLoad
    case viewWillDisappear(reason: ViewWillDisappearReason)
    case removeDelegates
    case initMiniPlayer
    case updateCurrentTime(percentage: Float)
    case onShuffle(active: Bool)
    case onPlayPause
    case onNext
    case onPrevious
    case onGoBackward
    case onGoForward
    case onRepeatPressed
    case onChangeSpeedModePressed
    case showPlaylist
    case `import`
    case sendToChat
    case share(sender: UIBarButtonItem?)
    case dismiss
    case refreshRepeatStatus
    case refreshShuffleStatus
    case showActionsforCurrentNode(sender: Any)
    case onSelectResumePlaybackContinuationDialog(playbackTime: TimeInterval)
    case onSelectRestartPlaybackContinuationDialog
}

@MainActor
protocol AudioPlayerViewRouting: AnyObject, Routing, Sendable {
    func dismiss(completion: @escaping () -> Void)
    func goToPlaylist(parentNodeName: String)
    func showMiniPlayer(node: MEGANode?, shouldReload: Bool)
    func showMiniPlayer(file: String, shouldReload: Bool)
    func importNode(_ node: MEGANode)
    func share(sender: UIBarButtonItem?)
    func sendToChat()
    func showAction(for node: MEGANode, isFileLink: Bool, sender: Any)
    func showTermsOfServiceViolationAlert()
}

extension AudioPlayerViewRouting {
    func dismiss() {
        dismiss(completion: {
            AudioPlayerManager.shared.clearFullScreenPlayerResources()
        })
    }
}

@objc enum RepeatMode: Int, CaseIterable {
    case none, loop, repeatOne
}

@objc enum SpeedMode: Int {
    case normal, oneAndAHalf, double, half
}

enum PlayerType: String, CaseIterable {
    case `default`, folderLink, fileLink, offline
}

@MainActor
final class AudioPlayerViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable {
        case reloadNodeInfo(name: String, artist: String, thumbnail: UIImage?, size: String?)
        case reloadThumbnail(thumbnail: UIImage)
        case reloadPlayerStatus(currentTime: String, remainingTime: String, percentage: Float, isPlaying: Bool)
        case showLoading(_ show: Bool)
        case updateRepeat(status: RepeatMode)
        case updateSpeed(mode: SpeedMode)
        case updateShuffle(status: Bool)
        case configureDefaultPlayer
        case configureOfflinePlayer
        case configureFileLinkPlayer
        case enableUserInteraction(_ enable: Bool, isSingleTrackPlayer: Bool)
        case didPausePlayback
        case didResumePlayback
        case displayPlaybackContinuationDialog(fileName: String, playbackTime: TimeInterval)
    }
    
    // MARK: - Private properties
    private let configEntity: AudioPlayerConfigEntity
    private weak var router: (any AudioPlayerViewRouting)?
    private let nodeInfoUseCase: (any NodeInfoUseCaseProtocol)?
    private let streamingInfoUseCase: (any StreamingInfoUseCaseProtocol)?
    private let offlineInfoUseCase: (any OfflineFileInfoUseCaseProtocol)?
    private let playbackContinuationUseCase: any PlaybackContinuationUseCaseProtocol
    private let audioPlayerUseCase: any AudioPlayerUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private let tracker: any AnalyticsTracking
    
    private var repeatItemsState: RepeatMode {
        didSet {
            invokeCommand?(.updateRepeat(status: repeatItemsState))
            switch repeatItemsState {
            case .none: configEntity.playerHandler.playerRepeatDisabled()
            case .loop:
                configEntity.playerHandler.playerRepeatAll(active: true)
                trackLoopIsEnabled()
            case .repeatOne:
                configEntity.playerHandler.playerRepeatOne(active: true)
                trackRepeatOneIsEnabled()
            }
        }
    }
    private var speedModeState: SpeedMode {
        didSet {
            invokeCommand?(.updateSpeed(mode: speedModeState))
            configEntity.playerHandler.changePlayer(speed: speedModeState)
           
            switch speedModeState {
            case .normal: trackAudioPlayerSpeedChange1X()
            case .oneAndAHalf: trackAudioPlayerSpeedChangeOneAndHalfX()
            case .double: trackAudioPlayerSpeedChange2X()
            case .half: trackAudioPlayerSpeedChangeHalfX()
            }
        }
    }
    private var shuffleModeEnabled: Bool {
        didSet {
            if shuffleModeEnabled {
                trackShuffleIsEnabled()
            }
            invokeCommand?(.updateShuffle(status: shuffleModeEnabled))
            configEntity.playerHandler.playerShuffle(active: shuffleModeEnabled)
        }
    }
    private(set) var isSingleTrackPlayer: Bool = false
    
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    var checkAppIsActive: @MainActor @Sendable () -> Bool = {
        UIApplication.shared.applicationState == .active
    }
    
    // MARK: - Init
    init(configEntity: AudioPlayerConfigEntity,
         router: some AudioPlayerViewRouting,
         nodeInfoUseCase: (some NodeInfoUseCaseProtocol)? = nil,
         streamingInfoUseCase: (some StreamingInfoUseCaseProtocol)? = nil,
         offlineInfoUseCase: (some OfflineFileInfoUseCaseProtocol)? = nil,
         playbackContinuationUseCase: some PlaybackContinuationUseCaseProtocol,
         audioPlayerUseCase: some AudioPlayerUseCaseProtocol,
         accountUseCase: some AccountUseCaseProtocol,
         networkMonitorUseCase: some NetworkMonitorUseCaseProtocol,
         tracker: some AnalyticsTracking
    ) {
        self.configEntity = configEntity
        self.router = router
        self.nodeInfoUseCase = nodeInfoUseCase
        self.streamingInfoUseCase = streamingInfoUseCase
        self.offlineInfoUseCase = offlineInfoUseCase
        self.playbackContinuationUseCase = playbackContinuationUseCase
        self.audioPlayerUseCase = audioPlayerUseCase
        self.accountUseCase = accountUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.repeatItemsState = configEntity.playerHandler.currentRepeatMode()
        self.speedModeState = configEntity.playerHandler.currentSpeedMode()
        self.shuffleModeEnabled = configEntity.playerHandler.isShuffleEnabled()
        self.tracker = tracker
        
        self.setupUpdateItemSubscription()
    }
    
    // MARK: - Private functions
    private func shouldInitializePlayer() -> Bool {
        if configEntity.playerHandler.isPlayerDefined() {
            guard let node = configEntity.node else {
                return configEntity.fileLink != configEntity.playerHandler.playerCurrentItem()?.url.absoluteString
            }
            if configEntity.fileLink != nil {
                guard let item = streamingInfoUseCase?.info(from: node), let itemNode = item.node,
                      let currentItem = configEntity.playerHandler.playerCurrentItem(), let currentItemNode = currentItem.node else {
                    return true
                }
                return itemNode != currentItemNode
            } else {
                return node.handle != configEntity.playerHandler.playerCurrentItem()?.node?.handle
            }
        } else {
            return true
        }
    }
    
    private func dismiss() {
        router?.dismiss()
    }
    
    private nonisolated func preparePlayer() async {
        if configEntity.playerType == .offline {
            guard let offlineFilePaths = configEntity.relatedFiles else {
                await dismiss()
                return
            }
            await initialize(with: offlineFilePaths)
        } else {
            guard let node = configEntity.node else {
                await dismiss()
                return
            }
            
            if await isTakenDownNode(node) {
                await router?.showTermsOfServiceViolationAlert()
                return
            }
            
            if !(streamingInfoUseCase?.isLocalHTTPProxyServerRunning() ?? true) {
                streamingInfoUseCase?.startServer()
            }
            await initialize(with: node)
        }
    }
    
    private func configurePlayer() {
        configEntity.playerHandler.configurePlayer(listener: self)
        
        guard !configEntity.playerHandler.isPlayerEmpty(),
              let tracks = configEntity.playerHandler.currentPlayer()?.tracks else {
            router?.dismiss()
            return
        }
        
        reloadNodeInfoWithCurrentItem()
        
        configurePlayerType(tracksCount: tracks.count)
    }
    
    private func configurePlayerType(tracksCount: Int) {
        switch configEntity.playerType {
        case .default, .folderLink, .offline:
            invokeCommand?(configEntity.playerType == .offline ? .configureOfflinePlayer : .configureDefaultPlayer)
            isSingleTrackPlayer = tracksCount == 1
        case .fileLink:
            invokeCommand?(.configureFileLinkPlayer)
            isSingleTrackPlayer = true
        }
    }
    
    private nonisolated func initialize(tracks: [AudioPlayerItem], currentTrack: AudioPlayerItem) async {
        let mutableTracks = await shift(tracks: tracks, startItem: currentTrack)
        
        if !(configEntity.playerHandler.isPlayerDefined()) {
            configEntity.playerHandler.setCurrent(player: AudioPlayer(), tracks: mutableTracks, playerListener: self)
        } else {
            if await shouldInitializePlayer() {
                await cleanPlayerStateForReuse()
                configEntity.playerHandler.addPlayer(tracks: mutableTracks)
                
                if configEntity.fileLink != nil && configEntity.playerHandler.isPlayerPlaying() {
                    configEntity.playerHandler.playerPause()
                }
            } else {
                await self.reloadNodeInfoWithCurrentItem()
            }
        }
        
        await configurePlayerType(tracksCount: tracks.count)
    }
    
    private nonisolated func cleanPlayerStateForReuse() async {
        await removePreviousQueuedTrackInPlayer()
        await refreshPlayerListener()
    }
    
    private nonisolated func removePreviousQueuedTrackInPlayer() async {
        configEntity.playerHandler.currentPlayer()?.queuePlayer = nil
        configEntity.playerHandler.currentPlayer()?.update(tracks: [])
    }
    
    private nonisolated func refreshPlayerListener() async {
        configEntity.playerHandler.currentPlayer()?.removeAllListeners()
        configEntity.playerHandler.currentPlayer()?.configure(listener: self)
    }
    
    private nonisolated func shift(tracks: [AudioPlayerItem], startItem: AudioPlayerItem) async -> [AudioPlayerItem] {
        if let allNodes = configEntity.allNodes, allNodes.isNotEmpty {
            let strategy = AudioPlayerAllAudioAsPlaylistShiftStrategy()
            return strategy.shift(tracks: tracks, startItem: startItem)
        } else {
            let strategy = AudioPlayerDefaultPlaylistShiftStrategy()
            return strategy.shift(tracks: tracks, startItem: startItem)
        }
    }

    // MARK: - Node Initialize
    private nonisolated func initialize(with node: MEGANode) async {
        if configEntity.fileLink != nil {
            guard let track = streamingInfoUseCase?.info(from: node) else {
                await dismiss()
                return
            }
            await initialize(tracks: [track], currentTrack: track)
        } else {
            if let allNodes = configEntity.allNodes, allNodes.isNotEmpty, await isCurrentUserNode(node) {
                await initializeTracksForAllAudioFilesAsPlaylist(from: node, allNodes)
            } else {
                guard let (currentTrack, children) = await getTracks(from: node) else {
                    guard let track = streamingInfoUseCase?.info(from: node) else {
                        await dismiss()
                        return
                    }
                    await initialize(tracks: [track], currentTrack: track)
                    return
                }
                await initialize(tracks: children, currentTrack: currentTrack)
            }
        }
    }
    
    private nonisolated func isCurrentUserNode(_ node: MEGANode) async -> Bool {
        accountUseCase.currentUserHandle == node.owner
    }
    
    private nonisolated func initializeTracksForAllAudioFilesAsPlaylist(from node: MEGANode, _ allNodes: [MEGANode]) async {
        let tracksFromNodes = allNodes.compactMap { streamingInfoUseCase?.info(from: $0) }
        guard tracksFromNodes.isNotEmpty,
            let currentTrack = await tracksFromNodes.async.first(where: { await $0.node?.handle == node.handle }) else {
            guard let track = streamingInfoUseCase?.info(from: node) else {
                await dismiss()
                return
            }
            await initialize(tracks: [track], currentTrack: track)
            return
        }
        await initialize(tracks: tracksFromNodes, currentTrack: currentTrack)
    }
    
    private nonisolated func getTracks(from node: MEGANode) async -> (currentTrack: AudioPlayerItem, childrenTracks: [AudioPlayerItem])? {
        guard
            let children = configEntity.isFolderLink
                ? nodeInfoUseCase?.folderChildrenInfo(fromParentHandle: node.parentHandle)
                : nodeInfoUseCase?.childrenInfo(fromParentHandle: node.parentHandle),
            let currentTrack = await children.async.first(where: { await $0.node?.handle == node.handle })
        else {
            return nil
        }
        
        return (currentTrack, children)
    }
    
    // MARK: - Offline Files Initialize
    private func initialize(with offlineFilePaths: [String]) async {
        guard let files = offlineInfoUseCase?.info(from: offlineFilePaths),
              let currentFilePath = configEntity.fileLink,
              let currentTrack = files.first(where: { $0.url.path == currentFilePath ||
                                                $0.url.absoluteString == currentFilePath }) else {
            invoke(command: .configureOfflinePlayer)
            reloadNodeInfoWithCurrentItem()
            dismiss()
            return
        }
        await initialize(tracks: files, currentTrack: currentTrack)
    }
    
    private func invoke(command: Command) {
        invokeCommand?(command)
    }
    
    private func reloadNodeInfoWithCurrentItem() {
        guard let currentItem = configEntity.playerHandler.playerCurrentItem() else { return }
        invokeCommand?(
            .reloadNodeInfo(
                name: currentItem.name,
                artist: currentItem.artist ?? "",
                thumbnail: currentItem.artwork,
                size: String.memoryStyleString(fromByteCount: configEntity.node?.size?.int64Value ?? Int64(0))
            )
        )
        
        configEntity.playerHandler.refreshCurrentItemState()
        
        invokeCommand?(.showLoading(false))
    }
    
    // MARK: - Analytics
    private func trackInitializeAudioPlayer() {
        tracker.trackAnalyticsEvent(with: AudioPlayerIsActivatedEvent())
    }
    
    private func trackShuffleIsEnabled() {
        tracker.trackAnalyticsEvent(with: AudioPlayerShuffleEnabledEvent())
    }
    
    private func trackLoopIsEnabled() {
        tracker.trackAnalyticsEvent(with: AudioPlayerLoopQueueEnabledEvent())
    }
    
    private func trackRepeatOneIsEnabled() {
        tracker.trackAnalyticsEvent(with: AudioPlayerLoopPlayingItemEnabledEvent())
    }
    
    private func trackAccessingAudioPlayerPlaylist() {
        tracker.trackAnalyticsEvent(with: AudioPlayerQueueButtonPressedEvent())
    }
    
    private func trackAudioPlayerSpeedChangeHalfX() {
        tracker.trackAnalyticsEvent(with: AudioPlayerSpeedChangeHalfXEvent())
    }

    private func trackAudioPlayerSpeedChange1X() {
        tracker.trackAnalyticsEvent(with: AudioPlayerSpeedChange1XEvent())
    }

    private func trackAudioPlayerSpeedChangeOneAndHalfX() {
        tracker.trackAnalyticsEvent(with: AudioPlayerSpeedChangeOneAndHalfXEvent())
    }

    private func trackAudioPlayerSpeedChange2X() {
        tracker.trackAnalyticsEvent(with: AudioPlayerSpeedChange2XEvent())
    }

    private func trackAudioPlayerForward15Seconds() {
        tracker.trackAnalyticsEvent(with: AudioPlayerForward15SecondsEvent())
    }

    private func trackAudioPlayerBack15Seconds() {
        tracker.trackAnalyticsEvent(with: AudioPlayerBack15SecondsEvent())
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: AudioPlayerAction) {
        switch action {
        case .onViewDidLoad:
            Task { [weak self] in
                guard let self, let node = configEntity.node else { return }
                if await isTakenDownNode(node) {
                    router?.showTermsOfServiceViolationAlert()
                    return
                }
                
                await audioPlayerUseCase.registerMEGADelegate()
            }
                
            if configEntity.allNodes == nil {
                configEntity.allNodes = configEntity.playerHandler.playerPlaylistItems()?.compactMap(\.node)
            }
            
            if shouldInitializePlayer() {
                trackInitializeAudioPlayer()
                invokeCommand?(.showLoading(true))
                Task {
                    await self.preparePlayer()
                }
            } else {
                invokeCommand?(.showLoading(false))
                configurePlayer()
            }
            
            invokeCommand?(.updateShuffle(status: configEntity.playerHandler.isShuffleEnabled()))
            invokeCommand?(.updateSpeed(mode: speedModeState))
        case .updateCurrentTime(let percentage):
            configEntity.playerHandler.playerProgressCompleted(percentage: percentage)
        case .onShuffle(let active):
            shuffleModeEnabled = active
        case .onPrevious:
            if configEntity.playerHandler.playerCurrentItemTime() == 0.0 && repeatItemsState == .repeatOne {
                repeatItemsState = .loop
            }
            configEntity.playerHandler.playPrevious()
        case .onPlayPause:
            configEntity.playerHandler.playerTogglePlay()
        case .onNext:
            if repeatItemsState == .repeatOne {
                repeatItemsState = .loop
            }
            configEntity.playerHandler.playNext()
        case .onGoBackward:
            trackAudioPlayerBack15Seconds()
            configEntity.playerHandler.goBackward()
        case .onGoForward:
            trackAudioPlayerForward15Seconds()
            configEntity.playerHandler.goForward()
        case .onRepeatPressed:
            if configEntity.playerType == .fileLink || configEntity.playerHandler.isSingleItemPlaylist() {
                repeatItemsState = switch repeatItemsState {
                case .none: .repeatOne
                default: .none
                }
            } else {
                repeatItemsState = switch repeatItemsState {
                case .none: .loop
                case .loop: .repeatOne
                case .repeatOne: .none
                }
            }
        case .onChangeSpeedModePressed:
            switch speedModeState {
            case .normal: speedModeState = .oneAndAHalf
            case .oneAndAHalf: speedModeState = .double
            case .double: speedModeState = .half
            case .half: speedModeState = .normal
            }
        case .showPlaylist:
            let parentNodeName = nodeInfoUseCase?.node(fromHandle: configEntity.node?.parentHandle ?? .invalid)?.name
            trackAccessingAudioPlayerPlaylist()
            router?.goToPlaylist(parentNodeName: parentNodeName ?? "")
        case .`import`:
            if let node = configEntity.node {
                router?.importNode(node)
            }
        case .sendToChat:
            router?.sendToChat()
        case .share(let sender):
            router?.share(sender: sender)
        case .dismiss:
            router?.dismiss()
        case .refreshRepeatStatus:
            invokeCommand?(.updateRepeat(status: repeatItemsState))
        case .refreshShuffleStatus:
            invokeCommand?(.updateShuffle(status: configEntity.playerHandler.isShuffleEnabled()))
        case .showActionsforCurrentNode(let sender):
            guard let node = configEntity.playerHandler.playerCurrentItem()?.node else { return }
            guard let nodeUseCase = nodeInfoUseCase,
                  let latestNode = nodeUseCase.node(fromHandle: node.handle) else {
                    self.router?.showAction(for: node, isFileLink: configEntity.playerType == .fileLink, sender: sender)
                    return
                }
            router?.showAction(for: latestNode, isFileLink: configEntity.playerType == .fileLink, sender: sender)
        case .onSelectResumePlaybackContinuationDialog(let playbackTime):
            configEntity.playerHandler.playerResumePlayback(from: playbackTime)
            playbackContinuationUseCase.setPreference(to: .resumePreviousSession)
        case .onSelectRestartPlaybackContinuationDialog:
            playbackContinuationUseCase.setPreference(to: .restartFromBeginning)
            configEntity.playerHandler.playerPlay()
        case .viewWillDisappear(let reason):
            switch reason {
            case .userInitiatedDismissal:
                guard networkMonitorUseCase.isConnected() else {
                    initMiniPlayer()
                    return
                }
                accountUseCase.isLoggedIn() ? initMiniPlayer() : requestStopAudioPlayerSession()
            case .systemPushedAnotherView:
                break
            }
        case .removeDelegates:
            removeDelegates()
        case .initMiniPlayer:
            initMiniPlayer()
        }
    }
    
    private func removeDelegates() {
        configEntity.playerHandler.removePlayer(listener: self)
        if !configEntity.playerHandler.isPlayerDefined() {
            streamingInfoUseCase?.stopServer()
        }
        Task { [audioPlayerUseCase] in
            await audioPlayerUseCase.unregisterMEGADelegate()
        }
    }
    
    private func isTakenDownNode(_ node: MEGANode) async -> Bool {
        guard let nodeInfoUseCase else {
            return false
        }
        do {
            return try await nodeInfoUseCase.isTakenDown(
                node: node,
                isFolderLink: configEntity.isFolderLink
            )
        } catch {
            return false
        }
    }
}

@MainActor
extension AudioPlayerViewModel: AudioPlayerObserversProtocol {
    nonisolated func audio(player: AVQueuePlayer, showLoading: Bool) {
        Task { @MainActor in
            invokeCommand?(.showLoading(showLoading))
        }
    }
    
    nonisolated func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, currentThumbnail: UIImage?) {
        if let thumbnail = currentThumbnail {
            Task { @MainActor in
                invokeCommand?(.reloadThumbnail(thumbnail: thumbnail))
            }
        }
    }
    
    nonisolated func audio(player: AVQueuePlayer, currentTime: Double, remainingTime: Double, percentageCompleted: Float, isPlaying: Bool) {
        Task { @MainActor in
            invokeCommand?(.reloadPlayerStatus(currentTime: currentTime.timeString, remainingTime: String(describing: "-\(remainingTime.timeString)"), percentage: percentageCompleted, isPlaying: isPlaying))
        }
    }
    
    nonisolated func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?) {
        Task { @MainActor in
            invokeCommand?(.reloadNodeInfo(name: name, artist: artist, thumbnail: thumbnail, size: nil))
        }
    }
    
    nonisolated func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?, url: String) {
        Task { @MainActor in
            if configEntity.fileLink != nil, !configEntity.isFolderLink {
                invokeCommand?(.reloadNodeInfo(name: name, artist: artist, thumbnail: thumbnail, size: String.memoryStyleString(fromByteCount: configEntity.node?.size?.int64Value ?? Int64(0))))
            } else {
                self.invokeCommand?(.reloadNodeInfo(name: name, artist: artist, thumbnail: thumbnail, size: String.memoryStyleString(fromByteCount: Int64(0))))
            }
        }
    }
    
    nonisolated func audioPlayerWillStartBlockingAction() {
        Task { @MainActor in
            invokeCommand?(.enableUserInteraction(false, isSingleTrackPlayer: isSingleTrackPlayer))
        }
    }
    
    nonisolated func audioPlayerDidFinishBlockingAction() {
        Task { @MainActor in
            invokeCommand?(.enableUserInteraction(true, isSingleTrackPlayer: isSingleTrackPlayer))
        }
    }
    
    nonisolated func audioPlayerDidPausePlayback() {
        Task { @MainActor in
            invokeCommand?(.didPausePlayback)
        }
    }
    
    nonisolated func audioPlayerDidResumePlayback() {
        Task { @MainActor in
            invokeCommand?(.didResumePlayback)
        }
    }
    
    nonisolated func audio(player: AVQueuePlayer, loopMode: Bool, shuffleMode: Bool, repeatOneMode: Bool) {
        Task { @MainActor in
            repeatItemsState = loopMode ? .loop : repeatOneMode ? .repeatOne : .none
            invokeCommand?(.updateShuffle(status: shuffleMode))
        }
    }
    
    nonisolated func audioPlayerDidFinishBuffering() {
        Task { @MainActor in
            if configEntity.playerHandler.currentSpeedMode() != speedModeState {
                configEntity.playerHandler.changePlayer(speed: speedModeState)
            }
        }
    }
    
    nonisolated func audioPlayerDidAddTracks() {
        guard let item = configEntity.playerHandler.playerCurrentItem() else { return }
        
        audioDidStartPlayingItem(item)
    }
    
    nonisolated func audioDidStartPlayingItem(_ item: AudioPlayerItem?) {
        Task { @MainActor in
            guard let item, let fingerprint = item.node?.toNodeEntity().fingerprint else {
                return
            }
            
            switch playbackContinuationUseCase.status(for: fingerprint) {
            case .displayDialog(let playbackTime):
                shouldDisplayPlaybackContinuationDialog(
                    fileName: item.name,
                    playbackTime: playbackTime
                )
            case .resumeSession(let playbackTime):
                configEntity.playerHandler.playerResumePlayback(from: playbackTime)
            case .startFromBeginning:
                guard let player = configEntity.playerHandler.currentPlayer() else { return }
                
                if player.currentIndex == 0 && player.resettingPlayback {
                    configEntity.playerHandler.playerProgressCompleted(percentage: 0)
                    player.resettingPlayback = false
                } else {
                    configEntity.playerHandler.playerResumePlayback(from: 0)
                }
            }
        }
    }
    
    private func shouldDisplayPlaybackContinuationDialog(
        fileName: String,
        playbackTime: TimeInterval
    ) {
        if checkAppIsActive() {
            invoke(
                command: .displayPlaybackContinuationDialog(
                    fileName: fileName,
                    playbackTime: playbackTime
                )
            )
            configEntity.playerHandler.playerPause()
        } else {
            playbackContinuationUseCase.setPreference(to: .resumePreviousSession)
            configEntity.playerHandler.playerResumePlayback(from: playbackTime)
        }
    }
    
    private func requestStopAudioPlayerSession() {
        if configEntity.playerHandler.isPlayerAlive() {
            configEntity.playerHandler.playerPause()
            configEntity.playerHandler.closePlayer()
            streamingInfoUseCase?.stopServer()
        }
    }
    
    private func initMiniPlayer() {
        switch configEntity.playerType {
        case .`default`:
            router?.showMiniPlayer(node: configEntity.playerHandler.playerCurrentItem()?.node, shouldReload: true)
        case .folderLink:
            router?.showMiniPlayer(file: configEntity.playerHandler.playerCurrentItem()?.url.absoluteString ?? "", shouldReload: true)
        case .fileLink:
            router?.showMiniPlayer(file: configEntity.fileLink ?? "", shouldReload: true)
        case .offline:
            router?.showMiniPlayer(file: configEntity.playerHandler.playerCurrentItem()?.url.absoluteString ?? "", shouldReload: true)
        }
    }
}

extension AudioPlayerViewModel {
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
        
        refreshItem(updatedNode)
    }
    
    private func refreshItem(_ updatedNode: NodeEntity) {
        guard let node = nodeInfoUseCase?.node(fromHandle: updatedNode.handle) else { return }
        
        configEntity.playerHandler.currentPlayer()?.refreshTrack(with: node)
        reloadNodeInfoWithCurrentItem()
    }
}
