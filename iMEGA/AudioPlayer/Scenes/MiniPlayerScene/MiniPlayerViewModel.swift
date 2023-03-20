import Foundation
import MEGAFoundation
import MEGADomain
import MEGAPresentation

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
    func isAFolderLinkPresenter() -> Bool
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
    private var configEntity: AudioPlayerConfigEntity
    private var shouldInitializePlayer: Bool = false
    private let router: MiniPlayerViewRouting
    private let nodeInfoUseCase: NodeInfoUseCaseProtocol?
    private let streamingInfoUseCase: StreamingInfoUseCaseProtocol?
    private let offlineInfoUseCase: OfflineFileInfoUseCaseProtocol?
    private let dispatchQueue: DispatchQueueProtocol
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(configEntity: AudioPlayerConfigEntity,
         router: MiniPlayerViewRouting,
         nodeInfoUseCase: NodeInfoUseCaseProtocol?,
         streamingInfoUseCase: StreamingInfoUseCaseProtocol?,
         offlineInfoUseCase: OfflineFileInfoUseCaseProtocol?,
         dispatchQueue: DispatchQueueProtocol = DispatchQueue.global()) {
        self.configEntity = configEntity
        self.router = router
        self.nodeInfoUseCase = nodeInfoUseCase
        self.streamingInfoUseCase = streamingInfoUseCase
        self.offlineInfoUseCase = offlineInfoUseCase
        self.dispatchQueue = dispatchQueue
        self.shouldInitializePlayer = configEntity.shouldResetPlayer
    }
    
    // MARK: - Node Init
    private func initialize(with node: MEGANode) {
        
        if configEntity.isFileLink {
            // play audio file link
            guard let track = streamingInfoUseCase?.info(from: node) else {
                router.dismiss()
                return
            }
            initialize(tracks: [track], currentTrack: track)
            return
        }
        
        let isNodePlaylist = node.name != nil && node.name!.mnz_isAudioPlayListPathExtension
        if isNodePlaylist {
            // play cloud audio playlist
            var childrenInPlaylist: [AudioPlayerItem] = []
            var currentTrack: AudioPlayerItem?
            let group = DispatchGroup()
            group.enter()
            
            node.readTextBasedFileContent { content in
                if content == nil {
                    self.router.dismiss()
                    group.leave()
                    return
                }
                let parser = CUEPlaylistParser(cueContent: content!)
                if parser.tracks.isEmpty {
                    self.router.dismiss()
                    group.leave()
                    return
                }
                guard let children = self.configEntity.isFolderLink ? self.nodeInfoUseCase?.folderChildrenInfo(fromParentHandle: node.parentHandle) :
                        self.nodeInfoUseCase?.childrenInfo(fromParentHandle: node.parentHandle) else {
                    self.router.dismiss()
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
                    self.router.dismiss()
                    group.leave()
                    return
                }
                currentTrack = childrenInPlaylist.first!
                group.leave()
            }
            group.wait()
            if childrenInPlaylist.isEmpty {
                router.dismiss()
                return
            } else {
                self.initialize(tracks: childrenInPlaylist, currentTrack: currentTrack!)
            }
            return
        }
        
        // play cloud audio file
        if let allChildrenNode = configEntity.isFolderLink ? nodeInfoUseCase?.folderChildrenInfo(fromParentHandle: node.parentHandle) :
            nodeInfoUseCase?.childrenInfo(fromParentHandle: node.parentHandle) {
            let childrenNodeWithoutPlaylist = allChildrenNode.filter({ !$0.name.mnz_isAudioPlayListPathExtension })
            let currentTrack = childrenNodeWithoutPlaylist.first(where: { $0.node?.handle == node.handle })
            if currentTrack != nil {
                initialize(tracks: childrenNodeWithoutPlaylist, currentTrack: currentTrack!)
            } else {
                router.dismiss()
                return
            }
        } else {
            guard let track = streamingInfoUseCase?.info(from: node) else {
                router.dismiss()
                return
            }
            initialize(tracks: [track], currentTrack: track)
        }
    }
    
    // MARK: - Offline Files Init
    private func initialize(with offlineFilePaths: [String]) {
        guard let files = offlineInfoUseCase?.info(from: offlineFilePaths),
              let currentFilePath = configEntity.fileLink,
              let currentTrack = files.first(where: { $0.url.path == currentFilePath }) else {
            router.dismiss()
            return
        }
        initialize(tracks: files, currentTrack: currentTrack)
    }
    
    // MARK: - Private functions
    private func initialize(tracks: [AudioPlayerItem], currentTrack: AudioPlayerItem) {
        let mutableTracks = shift(tracks: tracks, startItem: currentTrack)
        CrashlyticsLogger.log("[AudioPlayer] type: , \(configEntity.playerType)")
        resetConfigurationIfNeeded(nextCurrentTrack: currentTrack)
        configEntity.playerHandler.autoPlay(enable: configEntity.playerType != .fileLink)
        configEntity.playerHandler.addPlayer(tracks: mutableTracks)
        configurePlayer()
    }
    
    private func resetConfigurationIfNeeded(nextCurrentTrack: AudioPlayerItem) {
        switch configEntity.playerType {
        case .default:
            if let currentNode = configEntity.playerHandler.playerCurrentItem()?.node {
                guard let nextCurrentNode = nextCurrentTrack.node,
                      nextCurrentNode.parentHandle != currentNode.parentHandle else { return }
            }
            
        case .folderLink:
            guard !configEntity.playerHandler.playerTracksContains(url: nextCurrentTrack.url) else { return }
            
        case .offline:
            let nextCurrentItemDirectoryURL = nextCurrentTrack.url.deletingLastPathComponent()
            guard let currentItemDirectoryURL = configEntity.playerHandler.playerCurrentItem()?.url.deletingLastPathComponent(),
                  nextCurrentItemDirectoryURL != currentItemDirectoryURL else { return }
            
        default:
            break
        }
        
        configEntity.playerHandler.resetAudioPlayerConfiguration()
    }

    private func shift(tracks: [AudioPlayerItem], startItem: AudioPlayerItem) -> [AudioPlayerItem] {
        guard tracks.contains(startItem) else { return tracks }
        return tracks.shifted(tracks.firstIndex(of: startItem) ?? 0)
    }
    
    private func preparePlayer() {
        if configEntity.playerType == .offline {
            guard let offlineFilePaths = configEntity.relatedFiles else {
                router.dismiss()
                return
            }
            
            if let currentItem = configEntity.playerHandler.playerCurrentItem(), currentItem.url.path == configEntity.fileLink, currentItem.node == configEntity.node {
                configurePlayer()
                configEntity.playerHandler.resetCurrentItem()
            } else {
                initialize(with: offlineFilePaths)
            }
        } else {
            guard let node = configEntity.node else {
                router.dismiss()
                return
            }
            
            if !(streamingInfoUseCase?.isLocalHTTPProxyServerRunning() ?? true) {
                streamingInfoUseCase?.startServer()
            }
            
            if let currentItem = configEntity.playerHandler.playerCurrentItem(), currentItem.node == node {
                configurePlayer()
                configEntity.playerHandler.resetCurrentItem()
            } else {
                initialize(with: node)
            }
        }
    }
    
    private func configurePlayer() {
        configEntity.playerHandler.addPlayer(listener: self)
        
        guard !configEntity.playerHandler.isPlayerEmpty(), let currentItem = configEntity.playerHandler.playerCurrentItem() else {
            DispatchQueue.main.async { [weak self] in
                self?.router.dismiss()
            }
            return
        }
        invokeCommand?(.initTracks(currentItem: currentItem, queue: configEntity.playerHandler.playerPlaylistItems(), loopMode: configEntity.playerHandler.currentRepeatMode() == .loop))
        if let artworkImage = currentItem.artwork {
            invokeCommand?(.reloadNodeInfo(thumbnail: artworkImage))
        }
        
        configEntity.playerHandler.refreshCurrentItemState()
    }
    
    private func loadNode(from handle: HandleEntity, url: String?, completion: ((MEGANode?) -> Void)? = nil) {
        if let fileLink = configEntity.fileLink {
            nodeInfoUseCase?.publicNode(fromFileLink: fileLink) { [weak self] node in
                self?.configEntity.node = node
                completion?(node)
            }
        } else if configEntity.isFolderLink {
            guard let node = nodeInfoUseCase?.folderAuthNode(fromHandle: handle) else {
                nodeInfoUseCase?.publicNode(fromFileLink: url ?? "") { [weak self] node in
                    self?.configEntity.node = node
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
                    self?.configEntity.node = node
                    completion?(node)
                }
            }
        }
    }
    
    private func showFullScreenPlayer(_ node: MEGANode?, path: String?) {
        switch configEntity.playerType {
        case .`default`:
            return router.showPlayer(node: node, filePath: nil)
        case .folderLink, .fileLink, .offline:
            return router.showPlayer(node: node, filePath: configEntity.playerType == .fileLink ? configEntity.fileLink : path)
        }
    }
    
    private func closeMiniPlayer() {
        streamingInfoUseCase?.stopServer()
        if configEntity.isFolderLink, !router.isAFolderLinkPresenter() {
            nodeInfoUseCase?.folderLinkLogout()
        }
        router.dismiss()
    }
    
    private func deInitActions() {
        configEntity.playerHandler.removePlayer(listener: self)
        
        if configEntity.isFolderLink, !router.isAFolderLinkPresenter() {
            nodeInfoUseCase?.folderLinkLogout()
        }
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: MiniPlayerAction) {
        switch action {
        case .onViewDidLoad:
            invokeCommand?(.showLoading(shouldInitializePlayer))
            if shouldInitializePlayer {
                dispatchQueue.async(qos: .userInteractive) {
                    self.preparePlayer()
                }
            } else {
                configurePlayer()
            }
        case .onPlayPause:
            configEntity.playerHandler.playerTogglePlay()
        case .playItem(let item):
            if configEntity.playerHandler.currentRepeatMode() == .repeatOne {
                configEntity.playerHandler.playerRepeatAll(active: true)
            }
            configEntity.playerHandler.play(item: item)
        case .onClose:
            closeMiniPlayer()
        case .deinit:
            deInitActions()
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
