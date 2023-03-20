import Foundation
import MEGAFoundation
import MEGAPresentation

enum AudioPlayerAction: ActionType {
    case onViewDidLoad
    case updateCurrentTime(percentage: Float)
    case progressDragEventBegan
    case progressDragEventEnded
    case onShuffle(active: Bool)
    case onPlayPause
    case onNext
    case onPrevious
    case onGoBackward
    case onGoForward
    case onRepeatPressed
    case onChangeSpeedModePressed
    case showPlaylist
    case initMiniPlayer
    case `import`
    case sendToChat
    case share(sender: UIBarButtonItem?)
    case dismiss
    case refreshRepeatStatus
    case refreshShuffleStatus
    case showActionsforCurrentNode(sender: Any)
    case `deinit`
}

protocol AudioPlayerViewRouting: Routing {
    func dismiss()
    func goToPlaylist()
    func showMiniPlayer(node: MEGANode?, shouldReload: Bool)
    func showMiniPlayer(file: String, shouldReload: Bool)
    func importNode(_ node: MEGANode)
    func share(sender: UIBarButtonItem?)
    func sendToChat()
    func showAction(for node: MEGANode, sender: Any)
}

@objc enum RepeatMode: Int {
    case none, loop, repeatOne
}

@objc enum SpeedMode: Int {
    case normal, oneAndAHalf, double, half
}

enum PlayerType: String {
    case `default`, folderLink, fileLink, offline
}

final class AudioPlayerViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case reloadNodeInfo(name: String, artist: String, album: String, thumbnail: UIImage?, size: String?)
        case reloadThumbnail(thumbnail: UIImage)
        case reloadPlayerStatus(currentTime: String, remainingTime: String, percentage: Float, isPlaying: Bool)
        case showLoading(_ show: Bool)
        case updateRepeat(status: RepeatMode)
        case updateSpeed(mode: SpeedMode)
        case updateShuffle(status: Bool)
        case configureDefaultPlayer
        case configureOfflinePlayer
        case configureFileLinkPlayer(title: String, subtitle: String)
        case enableUserInteraction(_ enable: Bool)
        case didPausePlayback
        case didResumePlayback
        case shuffleAction(enabled: Bool)
        case goToPlaylistAction(enabled: Bool)
        case nextTrackAction(enabled: Bool)
    }
    
    // MARK: - Private properties
    private var configEntity: AudioPlayerConfigEntity
    private let router: AudioPlayerViewRouting
    private let nodeInfoUseCase: NodeInfoUseCaseProtocol?
    private let streamingInfoUseCase: StreamingInfoUseCaseProtocol?
    private let offlineInfoUseCase: OfflineFileInfoUseCaseProtocol?
    private let dispatchQueue: DispatchQueueProtocol
    private var repeatItemsState: RepeatMode {
        didSet {
            invokeCommand?(.updateRepeat(status: repeatItemsState))
            switch repeatItemsState {
            case .none: configEntity.playerHandler.playerRepeatDisabled()
            case .loop: configEntity.playerHandler.playerRepeatAll(active: true)
            case .repeatOne: configEntity.playerHandler.playerRepeatOne(active: true)
            }
        }
    }
    private var speedModeState: SpeedMode {
        didSet {
            invokeCommand?(.updateSpeed(mode: speedModeState))
            configEntity.playerHandler.changePlayer(speed: speedModeState)
        }
    }
    private var isSingleTrackPlayer: Bool = false
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(configEntity: AudioPlayerConfigEntity,
         router: AudioPlayerViewRouting,
         nodeInfoUseCase: NodeInfoUseCaseProtocol? = nil,
         streamingInfoUseCase: StreamingInfoUseCaseProtocol? = nil,
         offlineInfoUseCase: OfflineFileInfoUseCaseProtocol? = nil,
         dispatchQueue: DispatchQueueProtocol = DispatchQueue.global()) {
        self.configEntity = configEntity
        self.router = router
        self.nodeInfoUseCase = nodeInfoUseCase
        self.streamingInfoUseCase = streamingInfoUseCase
        self.offlineInfoUseCase = offlineInfoUseCase
        self.repeatItemsState = configEntity.playerHandler.currentRepeatMode()
        self.speedModeState = configEntity.playerHandler.currentSpeedMode()
        self.dispatchQueue = dispatchQueue
    }
    
    // MARK: - Private functions
    private func shouldInitializePlayer() -> Bool {
        if configEntity.playerHandler.isPlayerDefined() {
            guard let node = configEntity.node else {
                return configEntity.fileLink != configEntity.playerHandler.playerCurrentItem()?.url.absoluteString
            }
            if configEntity.fileLink != nil {
                return streamingInfoUseCase?.info(from: node)?.node != configEntity.playerHandler.playerCurrentItem()?.node
            } else {
                return node.handle != configEntity.playerHandler.playerCurrentItem()?.node?.handle
            }
        } else {
            return true
        }
    }
    
    private func preparePlayer() {
        if configEntity.playerType == .offline {
            guard let offlineFilePaths = configEntity.relatedFiles else {
                router.dismiss()
                return
            }
            initialize(with: offlineFilePaths)
        } else {
            guard let node = configEntity.node else {
                router.dismiss()
                return
            }
            
            if !(streamingInfoUseCase?.isLocalHTTPProxyServerRunning() ?? true) {
                streamingInfoUseCase?.startServer()
            }
            
            initialize(with: node)
        }
        configEntity.playerHandler.addPlayer(listener: self)
    }
    
    private func configurePlayer() {
        configEntity.playerHandler.addPlayer(listener: self)
        
        guard !configEntity.playerHandler.isPlayerEmpty(),
              let tracks = configEntity.playerHandler.currentPlayer()?.tracks,
              let currentTrack = configEntity.playerHandler.playerCurrentItem() else {
            DispatchQueue.main.async { [weak self] in
                self?.router.dismiss()
            }
            return
        }
        
        reloadNodeInfoWithCurrentItem()
        
        configurePlayerType(tracks: tracks, currentTrack: currentTrack)
    }
    
    private func configurePlayerType(tracks: [AudioPlayerItem], currentTrack: AudioPlayerItem) {
        switch configEntity.playerType {
        case .default, .folderLink, .offline:
            invokeCommand?(configEntity.playerType == .offline ? .configureOfflinePlayer : .configureDefaultPlayer)
            updateTracksActionStatus(enabled: tracks.count > 1)
            isSingleTrackPlayer = tracks.count == 1
        case .fileLink:
            invokeCommand?(.configureFileLinkPlayer(title: currentTrack.name, subtitle: Strings.Localizable.fileLink))
        }
    }
    
    private func initialize(tracks: [AudioPlayerItem], currentTrack: AudioPlayerItem) {
        let mutableTracks = shift(tracks: tracks, startItem: currentTrack)
        CrashlyticsLogger.log("[AudioPlayer] type: \(configEntity.playerType)")
        
        if !(configEntity.playerHandler.isPlayerDefined()) {
            configEntity.playerHandler.setCurrent(player: AudioPlayer(), autoPlayEnabled: !configEntity.isFileLink, tracks: mutableTracks)
        } else {
            if shouldInitializePlayer() {
                configEntity.playerHandler.autoPlay(enable: configEntity.playerType != .fileLink)
                configEntity.playerHandler.addPlayer(tracks: mutableTracks)
                
                if configEntity.fileLink != nil && configEntity.playerHandler.isPlayerPlaying() {
                    configEntity.playerHandler.playerPause()
                }
            } else {
                self.reloadNodeInfoWithCurrentItem()
            }
        }
        
        configurePlayerType(tracks: tracks, currentTrack: currentTrack)
    }
    
    private func shift(tracks: [AudioPlayerItem], startItem: AudioPlayerItem) -> [AudioPlayerItem] {
        guard tracks.contains(startItem) else { return tracks }
        return tracks.shifted(tracks.firstIndex(of: startItem) ?? 0)
    }
    
    private func updateTracksActionStatus(enabled: Bool) {
        invokeCommand?(.shuffleAction(enabled: enabled))
        invokeCommand?(.goToPlaylistAction(enabled: enabled))
        invokeCommand?(.nextTrackAction(enabled: enabled))
    }

    // MARK: - Node Initialize
    private func initialize(with node: MEGANode) {
        let dismissBlock: () -> Void = {
            DispatchQueue.main.async { [weak self] in
                self?.router.dismiss()
            }
        }
        if configEntity.fileLink != nil {
            guard let track = streamingInfoUseCase?.info(from: node) else {
                dismissBlock()
                return
            }
            initialize(tracks: [track], currentTrack: track)
        } else {
            if node.name != nil && node.name!.mnz_isAudioPlayListPathExtension {
                var childrenInPlaylist: [AudioPlayerItem] = []
                var currentTrack: AudioPlayerItem?
                let group = DispatchGroup()
                group.enter()
                
                node.readTextBasedFileContent { content in
                    if content == nil {
                        dismissBlock()
                        group.leave()
                        return
                    }
                    let parser = CUEPlaylistParser(cueContent: content!)
                    if parser.tracks.isEmpty {
                        dismissBlock()
                        group.leave()
                        return
                    }
                    guard let children = self.configEntity.isFolderLink ? self.nodeInfoUseCase?.folderChildrenInfo(fromParentHandle: node.parentHandle) :
                            self.nodeInfoUseCase?.childrenInfo(fromParentHandle: node.parentHandle) else {
                        dismissBlock()
                        group.leave()
                        return
                    }
                    childrenInPlaylist = parser.tracks.filter({ track in
                        children.contains { audioPlayerItem in
                            track.fileName == audioPlayerItem.name
                        }
                    }).map({ track in
                        let audioPlayerItems = children.filter { $0.name == track.fileName }
                        let audioPlayerItem = audioPlayerItems[0]
                        let newAudioPlayerItem = AudioPlayerItem(name: audioPlayerItem.name, url: audioPlayerItem.url, node: audioPlayerItem.node)
                        newAudioPlayerItem.title = track.title
                        newAudioPlayerItem.artist = track.artist
                        newAudioPlayerItem.album = track.album
                        newAudioPlayerItem.startTimeStamp = track.startTime
                        newAudioPlayerItem.configuredTimeOffsetFromLive = CMTime(seconds: track.startTime, preferredTimescale: 1)
                        newAudioPlayerItem.forwardPlaybackEndTime = track.endTime == nil ? CMTime.invalid : CMTime(seconds: track.endTime!, preferredTimescale: 1)
                        newAudioPlayerItem.reversePlaybackEndTime = CMTime(seconds: track.startTime, preferredTimescale: 1)
                        if !track.title.isEmpty {
                            newAudioPlayerItem.name = track.title
                        }
                        return newAudioPlayerItem
                    })
                    if childrenInPlaylist.isEmpty {
                        dismissBlock()
                        group.leave()
                        return
                    }
                    currentTrack = childrenInPlaylist.first!
                    group.leave()
                }
                group.wait()
                self.initialize(tracks: childrenInPlaylist, currentTrack: currentTrack!)
            } else {
                if let allChildrenNode = configEntity.isFolderLink ? nodeInfoUseCase?.folderChildrenInfo(fromParentHandle: node.parentHandle) :
                    nodeInfoUseCase?.childrenInfo(fromParentHandle: node.parentHandle) {
                    let childrenNodeWithoutPlaylist = allChildrenNode.filter({ !$0.name.mnz_isAudioPlayListPathExtension })
                    let currentTrack = childrenNodeWithoutPlaylist.first(where: { $0.node?.handle == node.handle })
                    if currentTrack != nil {
                        initialize(tracks: childrenNodeWithoutPlaylist, currentTrack: currentTrack!)
                    } else {
                        dismissBlock()
                        return
                    }
                } else {
                    guard let track = streamingInfoUseCase?.info(from: node) else {
                        dismissBlock()
                        return
                    }
                    initialize(tracks: [track], currentTrack: track)
                    return
                }
            }
        }
    }
    
    // MARK: - Offline Files Initialize
    private func initialize(with offlineFilePaths: [String]) {
        guard let files = offlineInfoUseCase?.info(from: offlineFilePaths),
              let currentFilePath = configEntity.fileLink,
              let currentTrack = files.first(where: { $0.url.path == currentFilePath ||
                                                $0.url.absoluteString == currentFilePath }) else {
            invokeCommand?(.configureOfflinePlayer)
            self.reloadNodeInfoWithCurrentItem()
            DispatchQueue.main.async { [weak self] in
                self?.router.dismiss()
            }
            return
        }
        initialize(tracks: files, currentTrack: currentTrack)
    }
    
    private func reloadNodeInfoWithCurrentItem() {
        guard let currentItem = configEntity.playerHandler.playerCurrentItem() else { return }
        invokeCommand?(.reloadNodeInfo(name: currentItem.name,
                                       artist: currentItem.artist ?? "",
                                       album: currentItem.album ?? "",
                                       thumbnail: currentItem.artwork,
                                       size: Helper.memoryStyleString(fromByteCount: configEntity.node?.size?.int64Value ?? Int64(0))))
        
        configEntity.playerHandler.refreshCurrentItemState()
        
        invokeCommand?(.showLoading(false))
    }

    // MARK: - Dispatch action
    func dispatch(_ action: AudioPlayerAction) {
        switch action {
        case .onViewDidLoad:
            if shouldInitializePlayer() {
                invokeCommand?(.showLoading(true))
                dispatchQueue.async(qos: .userInteractive) {
                    self.preparePlayer()
                }
            } else {
                invokeCommand?(.showLoading(false))
                configurePlayer()
            }
            invokeCommand?(.updateShuffle(status: configEntity.playerHandler.isShuffleEnabled()))
            invokeCommand?(.updateSpeed(mode: speedModeState))
        case .updateCurrentTime(let percentage):
            configEntity.playerHandler.playerProgressCompleted(percentage: percentage)
        case .progressDragEventBegan:
            configEntity.playerHandler.playerProgressDragEventBegan()
        case .progressDragEventEnded:
            configEntity.playerHandler.playerProgressDragEventEnded()
        case .onShuffle(let active):
            configEntity.playerHandler.playerShuffle(active: active)
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
            configEntity.playerHandler.goBackward()
        case .onGoForward:
            configEntity.playerHandler.goForward()
        case .onRepeatPressed:
            switch repeatItemsState {
            case .none: repeatItemsState = .loop
            case .loop: repeatItemsState = .repeatOne
            case .repeatOne: repeatItemsState = .none
            }
        case .onChangeSpeedModePressed:
            switch speedModeState {
            case .normal: speedModeState = .oneAndAHalf
            case .oneAndAHalf: speedModeState = .double
            case .double: speedModeState = .half
            case .half: speedModeState = .normal
            }
        case .showPlaylist:
            router.goToPlaylist()
        case .initMiniPlayer:
            switch configEntity.playerType {
            case .`default`:
                router.showMiniPlayer(node: configEntity.playerHandler.playerCurrentItem()?.node, shouldReload: true)
            case .folderLink:
                router.showMiniPlayer(file: configEntity.playerHandler.playerCurrentItem()?.url.absoluteString ?? "", shouldReload: true)
            case .fileLink:
                router.showMiniPlayer(file: configEntity.fileLink ?? "", shouldReload: true)
            case .offline:
                router.showMiniPlayer(file: configEntity.playerHandler.playerCurrentItem()?.url.absoluteString ?? "", shouldReload: true)
            }
        case .`import`:
            if let node = configEntity.node {
                router.importNode(node)
            }
        case .sendToChat:
            router.sendToChat()
        case .share(let sender):
            router.share(sender: sender)
        case .dismiss:
            router.dismiss()
        case .refreshRepeatStatus:
            invokeCommand?(.updateRepeat(status: repeatItemsState))
        case .refreshShuffleStatus:
            invokeCommand?(.updateShuffle(status: configEntity.playerHandler.isShuffleEnabled()))
        case .showActionsforCurrentNode(let sender):
            guard let node = configEntity.playerHandler.playerCurrentItem()?.node else { return }
            guard let nodeUseCase = nodeInfoUseCase,
                  let latestNode = nodeUseCase.node(fromHandle: node.handle) else {
                    self.router.showAction(for: node, sender: sender)
                    return
                }
            router.showAction(for: latestNode, sender: sender)
        case .deinit:
            configEntity.playerHandler.removePlayer(listener: self)
            if !configEntity.playerHandler.isPlayerDefined() {
                streamingInfoUseCase?.stopServer()
            }
        }
    }
}

extension AudioPlayerViewModel: AudioPlayerObserversProtocol {
    func audio(player: AVQueuePlayer, showLoading: Bool) {
        invokeCommand?(.showLoading(showLoading))
    }
    
    func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, currentThumbnail: UIImage?) {
        if let thumbnail = currentThumbnail {
            invokeCommand?(.reloadThumbnail(thumbnail: thumbnail))
        }
    }
    
    func audio(player: AVQueuePlayer, currentTime: Double, remainingTime: Double, percentageCompleted: Float, isPlaying: Bool) {
        if remainingTime > 0.0 { invokeCommand?(.showLoading(false)) }
        invokeCommand?(.reloadPlayerStatus(currentTime: currentTime.timeString, remainingTime: String(describing: "-\(remainingTime.timeString)"), percentage: percentageCompleted, isPlaying: isPlaying))
    }
    
    func audio(player: AVQueuePlayer, name: String, artist: String, album: String, thumbnail: UIImage?) {
        invokeCommand?(.reloadNodeInfo(name: name, artist: artist, album: album, thumbnail: thumbnail, size: nil))
    }
    
    func audio(player: AVQueuePlayer, name: String, artist: String, album: String, thumbnail: UIImage?, url: String) {
        if configEntity.fileLink != nil, !configEntity.isFolderLink {
            invokeCommand?(.reloadNodeInfo(name: name, artist: artist, album: album, thumbnail: thumbnail, size: Helper.memoryStyleString(fromByteCount: configEntity.node?.size?.int64Value ?? Int64(0))))
        } else {
            self.invokeCommand?(.reloadNodeInfo(name: name, artist: artist, album: album, thumbnail: thumbnail, size: Helper.memoryStyleString(fromByteCount: Int64(0))))
        }
    }
    
    func audioPlayerWillStartBlockingAction() {
        invokeCommand?(.enableUserInteraction(false))
    }
    
    func audioPlayerDidFinishBlockingAction() {
        invokeCommand?(.enableUserInteraction(true))
        if isSingleTrackPlayer {
            updateTracksActionStatus(enabled: false)
        }
    }
    
    func audioPlayerDidPausePlayback() {
        invokeCommand?(.didPausePlayback)
    }
    
    func audioPlayerDidResumePlayback() {
        invokeCommand?(.didResumePlayback)
    }
    
    func audio(player: AVQueuePlayer, loopMode: Bool, shuffleMode: Bool, repeatOneMode: Bool) {
        repeatItemsState = loopMode ? .loop : repeatOneMode ? .repeatOne : .none
        invokeCommand?(.updateShuffle(status: shuffleMode))
    }
    
    func audioPlayerDidFinishBuffering() {
        if configEntity.playerHandler.currentSpeedMode() != speedModeState {
            configEntity.playerHandler.changePlayer(speed: speedModeState)
        }
    }
}
