import Foundation

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
    case showPlaylist
    case initMiniPlayer
    case `import`
    case sendToContact
    case share
    case dismiss
    case refreshRepeatStatus
    case refreshShuffleStatus
    case showActionsforCurrentNode(sender: Any)
    case `deinit`
}

protocol AudioPlayerViewRouting: Routing {
    func dismiss()
    func goToPlaylist()
    func showMiniPlayer(shouldReload: Bool)
    func showOfflineMiniPlayer(file: String, shouldReload: Bool)
    func importNode(_ node: MEGANode)
    func share()
    func sendToContact()
    func showAction(for node: MEGANode, sender: Any)
}

@objc enum RepeatMode: Int {
    case none, loop, repeatOne
}

enum PlayerType: String {
    case `default`, folderLink, fileLink, offline
}

final class AudioPlayerViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case reloadNodeInfo(name: String, artist: String, thumbnail: UIImage?, size: String?)
        case reloadThumbnail(thumbnail: UIImage)
        case reloadPlayerStatus(currentTime: String, remainingTime: String, percentage: Float, isPlaying: Bool)
        case showLoading(_ show: Bool)
        case updateRepeat(status: RepeatMode)
        case updateShuffle(status: Bool)
        case configureDefaultPlayer
        case configureOfflinePlayer
        case configureFileLinkPlayer(title: String, subtitle: String)
        case enableUserInteraction(_ enable: Bool)
        case didPausePlayback
        case didResumePlayback
        case shuffleAction(enabled: Bool)
        case goToPlaylistAction(enabled: Bool)
    }
    
    var playerType: PlayerType = .default
    
    // MARK: - Private properties
    private let node: MEGANode?
    private let fileLink: String?
    private let selectedFilePath: String?
    private let filePaths: [String]?
    private let router: AudioPlayerViewRouting
    private let nodeInfoUseCase: NodeInfoUseCaseProtocol?
    private let streamingInfoUseCase: StreamingInfoUseCaseProtocol?
    private let offlineInfoUseCase: OfflineFileInfoUseCaseProtocol?
    private let dispatchQueue: DispatchQueueProtocol
    private var isFolderLink: Bool = false
    private var playerHandler: AudioPlayerHandlerProtocol
    private var repeatItemsState: RepeatMode {
        didSet {
            invokeCommand?(.updateRepeat(status: repeatItemsState))
            switch repeatItemsState {
            case .none: playerHandler.playerRepeatDisabled()
            case .loop: playerHandler.playerRepeatAll(active: true)
            case .repeatOne: playerHandler.playerRepeatOne(active: true)
            }
        }
    }
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Node Init
    init(node: MEGANode?,
         fileLink: String?,
         isFolderLink: Bool,
         router: AudioPlayerViewRouting,
         playerHandler: AudioPlayerHandlerProtocol,
         nodeInfoUseCase: NodeInfoUseCaseProtocol,
         streamingInfoUseCase: StreamingInfoUseCaseProtocol,
         dispatchQueue: DispatchQueueProtocol = DispatchQueue.global()) {
        self.node = node
        self.fileLink = fileLink
        self.isFolderLink = isFolderLink
        self.selectedFilePath = nil
        self.filePaths = nil
        self.router = router
        self.playerHandler = playerHandler
        self.nodeInfoUseCase = nodeInfoUseCase
        self.streamingInfoUseCase = streamingInfoUseCase
        self.offlineInfoUseCase = nil
        self.repeatItemsState = playerHandler.currentRepeatMode()
        self.dispatchQueue = dispatchQueue
    }
    
    // MARK: - Offline Init
    init(selectedFile: String,
         filePaths: [String]?,
         router: AudioPlayerViewRouting,
         playerHandler: AudioPlayerHandlerProtocol,
         offlineInfoUseCase: OfflineFileInfoUseCaseProtocol,
         dispatchQueue: DispatchQueueProtocol = DispatchQueue.global()) {
        self.node = nil
        self.fileLink = nil
        self.selectedFilePath = selectedFile
        self.filePaths = filePaths
        self.router = router
        self.playerHandler = playerHandler
        self.nodeInfoUseCase = nil
        self.streamingInfoUseCase = nil
        self.offlineInfoUseCase = offlineInfoUseCase
        self.repeatItemsState = playerHandler.currentRepeatMode()
        self.dispatchQueue = dispatchQueue
    }
    
    // MARK: - Private functions
    private func shouldInitializePlayer() -> Bool {
        if playerHandler.isPlayerDefined() {
            guard let node = node else {
                return URL(fileURLWithPath: selectedFilePath ?? "") != playerHandler.playerCurrentItem()?.url
            }
            if fileLink != nil {
                return streamingInfoUseCase?.info(from: node)?.node != playerHandler.playerCurrentItem()?.node
            } else {
                return node.handle != playerHandler.playerCurrentItem()?.node?.handle
            }
        } else {
            return true
        }
    }
    
    private func preparePlayer() {
        if !(streamingInfoUseCase?.isLocalHTTPProxyServerRunning() ?? true) {
            streamingInfoUseCase?.startServer()
        }
        
        if let node = node {
            initialize(with: node)
        } else if let offlineFilePaths = filePaths {
            initialize(with: offlineFilePaths)
        }
        playerHandler.addPlayer(listener: self)
    }
    
    private func configurePlayer() {
        playerHandler.addPlayer(listener: self)
        
        guard !playerHandler.isPlayerEmpty(),
              let tracks = playerHandler.currentPlayer()?.tracks,
              let currentTrack = playerHandler.playerCurrentItem() else {
            DispatchQueue.main.async { [weak self] in
                self?.router.dismiss()
            }
            return
        }
        
        reloadNodeInfoWithCurrentItem()
        
        if node == nil && (filePaths != nil) {
            playerType = .offline
        }
        configurePlayerType(tracks: tracks, currentTrack: currentTrack)
    }
    
    private func configurePlayerType(tracks: [AudioPlayerItem], currentTrack: AudioPlayerItem) {
        
        switch playerType {
        case .default, .folderLink:
            invokeCommand?(.configureDefaultPlayer)
            updateTracksActionStatus(enabled: tracks.count > 1)
        case .offline:
            invokeCommand?(.configureOfflinePlayer)
            updateTracksActionStatus(enabled: tracks.count > 1)
        case .fileLink:
            invokeCommand?(.configureFileLinkPlayer(title: currentTrack.name, subtitle: Strings.Localizable.fileLink))
        }
    }
    
    private func initialize(tracks: [AudioPlayerItem], currentTrack: AudioPlayerItem) {
        let mutableTracks = shift(tracks: tracks, startItem: currentTrack)
        CrashlyticsLogger.log("[AudioPlayer] type: \(playerType)")
        
        if !(playerHandler.isPlayerDefined()) {
            playerHandler.setCurrent(player: AudioPlayer(), autoPlayEnabled: fileLink == nil, tracks: mutableTracks)
        } else {
            if shouldInitializePlayer() {
                playerHandler.autoPlay(enable: playerType != .fileLink)
                playerHandler.addPlayer(tracks: mutableTracks)
                
                if fileLink != nil && playerHandler.isPlayerPlaying() {
                    playerHandler.playerPause()
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
    }

    // MARK: - Node Initialize
    private func initialize(with node: MEGANode) {
        if fileLink != nil {
            guard let track = streamingInfoUseCase?.info(from: node) else {
                DispatchQueue.main.async { [weak self] in
                    self?.router.dismiss()
                }
                return
            }
            
            playerType = .fileLink
            initialize(tracks: [track], currentTrack: track)
        } else {
            guard let children = isFolderLink ? nodeInfoUseCase?.folderChildrenInfo(fromParentHandle: node.parentHandle) :
                                                nodeInfoUseCase?.childrenInfo(fromParentHandle: node.parentHandle),
                  let currentTrack = children.first(where: { $0.node?.handle == node.handle }) else {
                
                guard let track = streamingInfoUseCase?.info(from: node) else {
                    DispatchQueue.main.async { [weak self] in
                        self?.router.dismiss()
                    }
                    return
                }
                
                playerType = .default
                initialize(tracks: [track], currentTrack: track)
                return
            }
            
            playerType = isFolderLink ? .folderLink : .default
            initialize(tracks: children, currentTrack: currentTrack)
        }
    }
    
    // MARK: - Offline Files Initialize
    private func initialize(with offlineFilePaths: [String]) {
        guard let files = offlineInfoUseCase?.info(from: offlineFilePaths),
              let currentFilePath = selectedFilePath,
              let currentTrack = files.first(where: { $0.url.path == currentFilePath ||
                                                $0.url.absoluteString == currentFilePath }) else {
            invokeCommand?(.configureOfflinePlayer)
            self.reloadNodeInfoWithCurrentItem()
            DispatchQueue.main.async { [weak self] in
                self?.router.dismiss()
            }
            return
        }
        
        playerType = .offline
        initialize(tracks: files, currentTrack: currentTrack)
    }
    
    private func reloadNodeInfoWithCurrentItem() {
        guard let currentItem = playerHandler.playerCurrentItem() else { return }
        invokeCommand?(.reloadNodeInfo(name: currentItem.name,
                                       artist: currentItem.artist ?? "",
                                       thumbnail: currentItem.artwork,
                                       size: Helper.memoryStyleString(fromByteCount: node?.size?.int64Value ?? Int64(0))))
        
        playerHandler.refreshCurrentItemState()
        
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
            invokeCommand?(.updateShuffle(status: playerHandler.isShuffleEnabled()))
        case .updateCurrentTime(let percentage):
            playerHandler.playerProgressCompleted(percentage: percentage)
        case .progressDragEventBegan:
            playerHandler.playerProgressDragEventBegan()
        case .progressDragEventEnded:
            playerHandler.playerProgressDragEventEnded()
        case .onShuffle(let active):
            playerHandler.playerShuffle(active: active)
        case .onPrevious:
            if playerHandler.playerCurrentItemTime() == 0.0 && repeatItemsState == .repeatOne {
                repeatItemsState = .loop
            }
            playerHandler.playPrevious()
        case .onPlayPause:
            playerHandler.playerTogglePlay()
        case .onNext:
            if repeatItemsState == .repeatOne {
                repeatItemsState = .loop
            }
            playerHandler.playNext()
        case .onGoBackward:
            playerHandler.goBackward()
        case .onGoForward:
            playerHandler.goForward()
        case .onRepeatPressed:
            switch repeatItemsState {
            case .none: repeatItemsState = .loop
            case .loop: repeatItemsState = .repeatOne
            case .repeatOne: repeatItemsState = .none
            }
        case .showPlaylist:
            router.goToPlaylist()
        case .initMiniPlayer:
            if selectedFilePath == nil {
                router.showMiniPlayer(shouldReload: true)
            } else {
                router.showOfflineMiniPlayer(file: playerHandler.playerCurrentItem()?.url.absoluteString ?? "", shouldReload: true)
            }
        case .`import`:
            if let node = node {
                router.importNode(node)
            }
        case .sendToContact:
            router.sendToContact()
        case .share:
            router.share()
        case .dismiss:
            router.dismiss()
        case .refreshRepeatStatus:
            invokeCommand?(.updateRepeat(status: repeatItemsState))
        case .refreshShuffleStatus:
            invokeCommand?(.updateShuffle(status: playerHandler.isShuffleEnabled()))
        case .showActionsforCurrentNode(let sender):
            guard let node = playerHandler.playerCurrentItem()?.node else { return }
            guard let nodeUseCase = nodeInfoUseCase,
                  let latestNode = nodeUseCase.node(fromHandle: node.handle) else {
                    self.router.showAction(for: node, sender: sender)
                    return
                }
            router.showAction(for: latestNode, sender: sender)
        case .deinit:
            playerHandler.removePlayer(listener: self)
            if !playerHandler.isPlayerDefined() {
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
        invokeCommand?(.reloadPlayerStatus(currentTime: NSString.mnz_string(fromTimeInterval: currentTime), remainingTime: String(describing: "-\(NSString.mnz_string(fromTimeInterval: remainingTime))"), percentage: percentageCompleted, isPlaying: isPlaying))
    }
    
    func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?) {
        invokeCommand?(.reloadNodeInfo(name: name, artist: artist, thumbnail: thumbnail, size: nil))
    }
    
    func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?, url: String) {
        if fileLink != nil, !isFolderLink {
            invokeCommand?(.reloadNodeInfo(name: name, artist: artist, thumbnail: thumbnail, size: Helper.memoryStyleString(fromByteCount: node?.size?.int64Value ?? Int64(0))))
        } else {
            self.invokeCommand?(.reloadNodeInfo(name: name, artist: artist, thumbnail: thumbnail, size: Helper.memoryStyleString(fromByteCount: Int64(0))))
        }
    }
    
    func audioPlayerWillStartBlockingAction() {
        invokeCommand?(.enableUserInteraction(false))
    }
    
    func audioPlayerDidFinishBlockingAction() {
        invokeCommand?(.enableUserInteraction(true))
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
}
