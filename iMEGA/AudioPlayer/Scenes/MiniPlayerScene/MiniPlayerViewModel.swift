import Combine
import Foundation
import MEGADomain
import MEGAFoundation
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

final class MiniPlayerViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        case reloadNodeInfo(thumbnail: UIImage?, name: String)
        case reloadPlayerStatus(percentage: Float, isPlaying: Bool)
        case initTracks(currentItem: AudioPlayerItem, queue: [AudioPlayerItem]?, loopMode: Bool)
        case change(currentItem: AudioPlayerItem, indexPath: IndexPath)
        case reload(currentItem: AudioPlayerItem)
        case reloadAt(_ index: Int)
        case showLoading(_ show: Bool)
        case enableUserInteraction(_ enable: Bool)
    }
    
    // MARK: - Private properties
    private(set) var configEntity: AudioPlayerConfigEntity
    private var shouldInitializePlayer: Bool = false
    private let router: any MiniPlayerViewRouting
    private let nodeInfoUseCase: (any NodeInfoUseCaseProtocol)?
    private let streamingInfoUseCase: (any StreamingInfoUseCaseProtocol)?
    private let offlineInfoUseCase: (any OfflineFileInfoUseCaseProtocol)?
    private let playbackContinuationUseCase: any PlaybackContinuationUseCaseProtocol
    private let audioPlayerUseCase: any AudioPlayerUseCaseProtocol
    private let dispatchQueue: any DispatchQueueProtocol
    private let sdk: MEGASdk
    
    private var subscriptions = [AnyCancellable]()
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(configEntity: AudioPlayerConfigEntity,
         router: some MiniPlayerViewRouting,
         nodeInfoUseCase: (any NodeInfoUseCaseProtocol)?,
         streamingInfoUseCase: (any StreamingInfoUseCaseProtocol)?,
         offlineInfoUseCase: (any OfflineFileInfoUseCaseProtocol)?,
         playbackContinuationUseCase: any PlaybackContinuationUseCaseProtocol,
         audioPlayerUseCase: some AudioPlayerUseCaseProtocol,
         sdk: MEGASdk = MEGASdk(),
         dispatchQueue: some DispatchQueueProtocol = DispatchQueue.global()
    ) {
        self.configEntity = configEntity
        self.router = router
        self.nodeInfoUseCase = nodeInfoUseCase
        self.streamingInfoUseCase = streamingInfoUseCase
        self.offlineInfoUseCase = offlineInfoUseCase
        self.playbackContinuationUseCase = playbackContinuationUseCase
        self.audioPlayerUseCase = audioPlayerUseCase
        self.sdk = sdk
        self.dispatchQueue = dispatchQueue
        self.shouldInitializePlayer = configEntity.shouldResetPlayer
        super.init()
        
        self.setupUpdateItemSubscription()
    }
    
    // MARK: - Node Init
    private func initialize(with node: MEGANode) {
        if configEntity.isFileLink {
            guard let track = streamingInfoUseCase?.info(from: node) else {
                router.dismiss()
                return
            }
            initialize(tracks: [track], currentTrack: track)
        } else {
            guard let children = configEntity.isFolderLink ? nodeInfoUseCase?.folderChildrenInfo(fromParentHandle: node.parentHandle) :
                                                nodeInfoUseCase?.childrenInfo(fromParentHandle: node.parentHandle),
                  let currentTrack = children.first(where: { $0.node?.handle == node.handle }) else {
                
                guard let track = streamingInfoUseCase?.info(from: node) else {
                    router.dismiss()
                    return
                }
                initialize(tracks: [track], currentTrack: track)
                return
            }
            initialize(tracks: children, currentTrack: currentTrack)
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
        
        currentItem.name = presentableName(currentItem.name)
        
        invokeCommand?(.initTracks(currentItem: currentItem, queue: configEntity.playerHandler.playerPlaylistItems(), loopMode: configEntity.playerHandler.currentRepeatMode() == .loop))
        if let artworkImage = currentItem.artwork {
            invokeCommand?(.reloadNodeInfo(thumbnail: artworkImage, name: presentableName(configEntity.node?.name ?? "")))
        }
        
        configEntity.playerHandler.refreshCurrentItemState()
    }
    
    private func presentableName(_ originalTrackName: String) -> String {
        let nameUpdateCheckerViewModel = AudioPlayerTrackNameUpdateCheckerViewModel(
            configEntity: configEntity,
            originalTrackName: originalTrackName
        )
        return nameUpdateCheckerViewModel.presentableName()
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
        configEntity.playerHandler.removePlayer(listener: self)
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
        
        Task {
            await audioPlayerUseCase.unregisterMEGADelegate()
        }
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: MiniPlayerAction) {
        switch action {
        case .onViewDidLoad:
            Task {
                await audioPlayerUseCase.registerMEGADelegate()
            }
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
            if let configNode = configEntity.node {
                let isFileRenamed = configNode.name != node?.name
                let currentNode = isFileRenamed ? configEntity.node : node
                configEntity.node = currentNode
                showFullScreenPlayer(currentNode, path: filePath)
            } else {
                configEntity.node = node
                showFullScreenPlayer(node, path: filePath)
            }
        }
    }
    
    private func currentItem(from updatedNode: MEGANode) -> AudioPlayerItem? {
        guard
            let currentPlayingNode = configEntity.node, updatedNode.handle == currentPlayingNode.handle,
            let newNodeName = updatedNode.name ?? currentPlayingNode.name,
            let currentItem = configEntity.playerHandler.playerCurrentItem()
        else {
            return nil
        }
        currentItem.name = newNodeName
        return currentItem
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
        invokeCommand?(.reloadNodeInfo(thumbnail: currentThumbnail, name: presentableName(currentItem?.name ?? "")))
    }
    
    func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?, url: String) {
        invokeCommand?(.reloadNodeInfo(thumbnail: thumbnail, name: presentableName(name)))
    }
    
    func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?) {
        invokeCommand?(.reloadNodeInfo(thumbnail: thumbnail, name: presentableName(name)))
    }
    
    func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, indexPath: IndexPath?) {
        guard let currentItem = currentItem, let indexPath = indexPath else { return }
        invokeCommand?(.change(currentItem: currentItem, indexPath: indexPath))
    }
    
    func audio(player: AVQueuePlayer, reload item: AudioPlayerItem?) {
        guard let currentItem = item else { return }
        currentItem.name = presentableName(currentItem.name)
        invokeCommand?(.reload(currentItem: currentItem))
    }
    
    func audioPlayerWillStartBlockingAction() {
        invokeCommand?(.enableUserInteraction(false))
    }
    
    func audioPlayerDidFinishBlockingAction() {
        invokeCommand?(.enableUserInteraction(true))
    }
    
    func audioDidStartPlayingItem(_ item: AudioPlayerItem?) {
        guard let item, let fingerprint = item.node?.toNodeEntity().fingerprint else {
            return
        }
        
        switch playbackContinuationUseCase.status(for: fingerprint) {
        case .displayDialog(let playbackTime):
            playbackContinuationUseCase.setPreference(to: .resumePreviousSession)
            configEntity.playerHandler.playerResumePlayback(from: playbackTime)
        case .resumeSession(let playbackTime):
            configEntity.playerHandler.playerResumePlayback(from: playbackTime)
        case .startFromBeginning: break
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
            nodeList.count > 0,
            let updatedNode = nodeList.first,
            let allNodes = configEntity.allNodes
        else {
            return
        }
        
        let shouldRefreshItem = allNodes.contains { $0.handle == updatedNode.handle }
        guard shouldRefreshItem else { return }
        
        refreshItem(updatedNode)
    }
    
    private func refreshItem(_ updatedEntity: NodeEntity) {
        guard let node = updatedEntity.toMEGANode(in: sdk) else { return }
        configEntity.node = node
        
        refreshItemUI(with: node, updatedEntity: updatedEntity)
    }
    
    private func refreshItemUI(with updatedNode: MEGANode, updatedEntity: NodeEntity) {
        let isDisplayingCurrentItem = configEntity.playerHandler.currentPlayer()?.currentItem()?.node?.handle == updatedEntity.handle
        if isDisplayingCurrentItem {
            guard let currentItem = currentItem(from: updatedNode) else { return }
            invokeCommand?(.reload(currentItem: currentItem))
        } else {
            guard
                let tracks = configEntity.playerHandler.currentPlayer()?.tracks,
                let index = tracks.firstIndex(where: { $0.node?.handle == updatedEntity.handle })
            else {
                return
            }
            invokeCommand?(.reloadAt(index))
        }
    }
}
