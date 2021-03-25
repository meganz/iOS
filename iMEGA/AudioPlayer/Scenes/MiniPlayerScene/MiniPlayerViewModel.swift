import Foundation

enum MiniPlayerAction: ActionType {
    case onViewDidLoad
    case onPlayPause
    case playItem(AudioPlayerItem)
    case onClose
    case `deinit`
    case showPlayer(MEGANode?, String?)
}

protocol MiniPlayerViewRouting: Routing {
    func dismiss()
    func showPlayer(node: MEGANode?, filePath: String?)
}

final class MiniPlayerViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case reloadNodeInfo(thumbnail: UIImage?)
        case reloadPlayerStatus(percentage: Float, isPlaying: Bool)
        case initTracks(currentItem: AudioPlayerItem, queue: [AudioPlayerItem]?, loopMode: Bool)
        case change(currentItem: AudioPlayerItem, indexPath: IndexPath)
        case reload(currentItem: AudioPlayerItem)
        case showLoading(_ show: Bool)
        case enableUserInteraction(_ enable: Bool)
    }
    
    // MARK: - Private properties
    private var node: MEGANode?
    private var fileLink: String?
    private var isFolderLink: Bool = false
    private var shouldInitializePlayer: Bool = false
    private let filePaths: [String]?
    private let router: MiniPlayerViewRouting
    private let playerHandler: AudioPlayerHandlerProtocol
    private let nodeInfoUseCase: NodeInfoUseCaseProtocol?
    private let streamingInfoUseCase: StreamingInfoUseCaseProtocol?
    private let offlineInfoUseCase: OfflineFileInfoUseCaseProtocol?
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    var playerType: PlayerType = .default
    
    // MARK: - Init
    init(fileLink: String?,
         filePaths: [String]?,
         isFolderLink: Bool,
         router: MiniPlayerViewRouting,
         playerHandler: AudioPlayerHandlerProtocol,
         nodeInfoUseCase: NodeInfoUseCaseProtocol?,
         streamingInfoUseCase: StreamingInfoUseCaseProtocol?,
         offlineInfoUseCase: OfflineFileInfoUseCaseProtocol?) {
        self.router = router
        self.fileLink = fileLink
        self.filePaths = filePaths
        self.isFolderLink = isFolderLink
        self.playerHandler = playerHandler
        self.nodeInfoUseCase = nodeInfoUseCase
        self.streamingInfoUseCase = streamingInfoUseCase
        self.offlineInfoUseCase = offlineInfoUseCase
    }
    
    // MARK: - Init to reset player
    convenience init(node: MEGANode?,
         fileLink: String?,
         filePaths: [String]?,
         isFolderLink: Bool,
         router: MiniPlayerViewRouting,
         playerHandler: AudioPlayerHandlerProtocol,
         nodeInfoUseCase: NodeInfoUseCaseProtocol?,
         streamingInfoUseCase: StreamingInfoUseCaseProtocol?,
         offlineInfoUseCase: OfflineFileInfoUseCaseProtocol?) {
        
        self.init(fileLink: fileLink, filePaths: filePaths, isFolderLink: isFolderLink, router: router, playerHandler: playerHandler, nodeInfoUseCase: nodeInfoUseCase, streamingInfoUseCase: streamingInfoUseCase, offlineInfoUseCase: offlineInfoUseCase)
        self.node = node
        self.shouldInitializePlayer = true
    }
    
    // MARK: - Node Init
    private func initialize(with node: MEGANode) {
        if fileLink != nil {
            guard let track = streamingInfoUseCase?.info(from: node) else {
                router.dismiss()
                return
            }
            playerType = .fileLink
            initialize(tracks: [track], currentTrack: track)
        } else {
            guard let children = isFolderLink ? nodeInfoUseCase?.folderChildrenInfo(fromParentHandle: node.parentHandle) :
                                                nodeInfoUseCase?.childrenInfo(fromParentHandle: node.parentHandle),
                  let currentTrack = children.first(where: { $0.node?.handle == node.handle }) else {
                
                guard let track = streamingInfoUseCase?.info(from: node) else {
                    router.dismiss()
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
    
    // MARK: - Offline Files Init
    private func initialize(with offlineFilePaths: [String]) {
        guard let files = offlineInfoUseCase?.info(from: offlineFilePaths),
              let currentFilePath = fileLink,
              let currentTrack = files.first(where: { $0.url.path == currentFilePath }) else {
            router.dismiss()
            return
        }
        
        playerType = .offline
        initialize(tracks: files, currentTrack: currentTrack)
    }
    
    // MARK: - Private functions
    private func initialize(tracks: [AudioPlayerItem], currentTrack: AudioPlayerItem) {
        var mutableTracks = tracks
        mutableTracks.bringToFront(item: currentTrack)
        playerHandler.autoPlay(enable: playerType != .folderLink)
        playerHandler.addPlayer(tracks: mutableTracks)
        configurePlayer()
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
    }
    
    private func configurePlayer() {
        playerHandler.addPlayer(listener: self)
        
        guard !playerHandler.isPlayerEmpty(), let currentItem = playerHandler.playerCurrentItem() else {
            router.dismiss()
            return
        }
        invokeCommand?(.initTracks(currentItem: currentItem, queue: playerHandler.playerPlaylistItems(), loopMode: playerHandler.currentRepeatMode() == .loop))
        if let artworkImage = currentItem.artwork {
            invokeCommand?(.reloadNodeInfo(thumbnail: artworkImage))
        }
        invokeCommand?(.showLoading(!playerHandler.isPlayerPaused()))
        
        playerHandler.refreshCurrentItemState()
    }
    
    private func loadNode(from handle: NodeHandle, url: String?, completion: ((MEGANode?) -> Void)? = nil) {
        if let fileLink = fileLink {
            nodeInfoUseCase?.publicNode(fromFileLink: fileLink) { [weak self] node in
                self?.node = node
                completion?(node)
            }
        } else if isFolderLink {
            guard let node = nodeInfoUseCase?.folderAuthNode(fromHandle: handle) else {
                nodeInfoUseCase?.publicNode(fromFileLink: url ?? "") { [weak self] node in
                    self?.node = node
                    completion?(node)
                }
                return
            }
            completion?(node)
        } else {
            if let node = nodeInfoUseCase?.node(fromHandle: handle) ?? streamingInfoUseCase?.info(from: handle) {
                completion?(node)
            } else {
                nodeInfoUseCase?.publicNode(fromFileLink: url ?? "") { [weak self] node in
                    self?.node = node
                    completion?(node)
                }
            }
        }
    }
    
    private func showFullScreenPlayer(_ node: MEGANode?, path: String?) {
        router.showPlayer(node: node, filePath: path)
    }
    
    private func closeMiniPlayer() {
        streamingInfoUseCase?.stopServer()
        if isFolderLink {
            nodeInfoUseCase?.folderLinkLogout()
        }
        router.dismiss()
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: MiniPlayerAction) {
        switch action {
        case .onViewDidLoad:
            shouldInitializePlayer ? preparePlayer() : configurePlayer()
        case .onPlayPause:
            playerHandler.playerTogglePlay()
        case .playItem(let item):
            playerHandler.play(item: item)
        case .onClose:
            closeMiniPlayer()
        case .deinit:
            playerHandler.removePlayer(listener: self)
        case .showPlayer(let node, let filePath):
            showFullScreenPlayer(node, path: filePath)
        }
    }
}

extension MiniPlayerViewModel: AudioPlayerObserversProtocol {
    func audio(player: AVQueuePlayer, showLoading: Bool) {
        invokeCommand?(.showLoading(showLoading))
    }
    
    func audio(player: AVQueuePlayer, currentTime: Double, remainingTime: Double, percentageCompleted: Float, isPlaying: Bool) {
        invokeCommand?(.reloadPlayerStatus(percentage: percentageCompleted, isPlaying: isPlaying))
    }
    
    func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, currentThumbnail: UIImage?) {
        invokeCommand?(.reloadNodeInfo(thumbnail: currentThumbnail))
    }
    
    func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?, url: String) {
        invokeCommand?(.reloadNodeInfo(thumbnail: thumbnail))
    }
    
    func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?) {
        invokeCommand?(.reloadNodeInfo(thumbnail: thumbnail))
    }
    
    func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, indexPath: IndexPath?) {
        guard let currentItem = currentItem, let indexPath = indexPath else { return }
        invokeCommand?(.change(currentItem: currentItem, indexPath: indexPath))
    }
    
    func audio(player: AVQueuePlayer, reload item: AudioPlayerItem?) {
        guard let currentItem = item else { return }
        invokeCommand?(.reload(currentItem: currentItem))
    }
    
    func audioPlayerWillStartBlockingAction() {
        invokeCommand?(.enableUserInteraction(false))
    }
    
    func audioPlayerDidFinishBlockingAction() {
        invokeCommand?(.enableUserInteraction(true))
    }
}
