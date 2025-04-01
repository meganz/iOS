import Combine
import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAFoundation

enum MiniPlayerAction: ActionType {
    case onViewDidLoad
    case onPlayPause
    case playItem(AudioPlayerItem)
    case onClose
    case showPlayer(MEGANode?, String?)
    case scrollToCurrentItem
}

@MainActor
protocol MiniPlayerViewRouting: Routing {
    func dismiss()
    func showPlayer(node: MEGANode?, filePath: String?)
    func isAFolderLinkPresenter() -> Bool
}

@MainActor
final class MiniPlayerViewModel: ViewModelType {
    enum Command: CommandType, Equatable, Sendable {
        case reloadNodeInfo(thumbnail: UIImage?)
        case reloadPlayerStatus(percentage: Float, isPlaying: Bool)
        case initTracks(currentItem: AudioPlayerItem, queue: [AudioPlayerItem]?, loopMode: Bool)
        case change(currentItem: AudioPlayerItem, indexPath: IndexPath)
        case reload(item: AudioPlayerItem)
        case showLoading(_ show: Bool)
        case enableUserInteraction(_ enable: Bool)
        case scrollToItem(indexPath: IndexPath)
    }
    
    // MARK: - Private properties
    private let configEntity: AudioPlayerConfigEntity
    private let shouldInitializePlayer: Bool
    private let router: any MiniPlayerViewRouting
    private let nodeInfoUseCase: (any NodeInfoUseCaseProtocol)?
    private let streamingInfoUseCase: (any StreamingInfoUseCaseProtocol)?
    private let offlineInfoUseCase: (any OfflineFileInfoUseCaseProtocol)?
    private let playbackContinuationUseCase: any PlaybackContinuationUseCaseProtocol
    private let audioPlayerUseCase: any AudioPlayerUseCaseProtocol
    private let sdk: MEGASdk
    
    private var subscriptions = Set<AnyCancellable>()
    
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
         sdk: MEGASdk = .shared
    ) {
        self.configEntity = configEntity
        self.router = router
        self.nodeInfoUseCase = nodeInfoUseCase
        self.streamingInfoUseCase = streamingInfoUseCase
        self.offlineInfoUseCase = offlineInfoUseCase
        self.playbackContinuationUseCase = playbackContinuationUseCase
        self.audioPlayerUseCase = audioPlayerUseCase
        self.sdk = sdk
        self.shouldInitializePlayer = configEntity.shouldResetPlayer
        
        self.setupUpdateItemSubscription()
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: MiniPlayerAction) {
        switch action {
        case .onViewDidLoad:
            Task.detached { [weak self] in
                guard let self, let node = configEntity.node, let nodeInfoUseCase else { return }
                let isTakenDown = try await nodeInfoUseCase.isTakenDown(node: node, isFolderLink: configEntity.isFolderLink)
                if isTakenDown {
                    await closeMiniPlayer()
                    return
                }
                
                await audioPlayerUseCase.registerMEGADelegate()
            }
            invoke(command: .showLoading(shouldInitializePlayer))
            determinePlayerSetupOnViewDidLoad()
        case .onPlayPause:
            configEntity.playerHandler.playerTogglePlay()
        case .playItem(let item):
            if configEntity.playerHandler.currentRepeatMode() == .repeatOne {
                configEntity.playerHandler.playerRepeatAll(active: true)
            }
            configEntity.playerHandler.play(item: item)
        case .onClose:
            closeMiniPlayer()
        case .showPlayer(let node, let filePath):
            showFullScreenPlayer(node, path: filePath)
        case .scrollToCurrentItem:
            if let currentItem = configEntity.playerHandler.playerCurrentItem(),
               let queue = configEntity.playerHandler.playerPlaylistItems(),
               let index = queue.firstIndex(of: currentItem) {
                let indexPath = IndexPath(row: index, section: 0)
                invokeCommand?(.scrollToItem(indexPath: indexPath))
            }
        }
    }
    
    private func invoke(command: Command) {
        invokeCommand?(command)
    }
    
    private func determinePlayerSetupOnViewDidLoad() {
        guard shouldInitializePlayer else {
            configurePlayer()
            configEntity.playerHandler.refreshCurrentItemState()
            return
        }
        
        configEntity.playerHandler.resettingAudioPlayer(shouldResetPlayback: configEntity.playerType != .fileLink)
        
        Task.detached {
            await self.preparePlayer(isOffline: self.configEntity.playerType == .offline)
        }
    }
    
    private nonisolated func preparePlayer(isOffline: Bool) async {
        guard isOffline else {
            await preparePlayerForNonOfflinePlayerType()
            return
        }
        await preparePlayerForOfflinePlayerType()
    }
    
    private func dismiss() {
        router.dismiss()
    }
    
    private func preparePlayerForOfflinePlayerType() async {
        guard let offlineFilePaths = configEntity.relatedFiles else {
            dismiss()
            return
        }
        
        guard
            let currentItem = configEntity.playerHandler.playerCurrentItem(),
            currentItem.url.path == configEntity.fileLink,
            currentItem.node == configEntity.node
        else {
            await initialize(with: offlineFilePaths)
            return
        }
        configurePlayer()
        configEntity.playerHandler.resetCurrentItem(shouldResetPlayback: configEntity.playerType != .fileLink)
    }
    
    private func preparePlayerForNonOfflinePlayerType() async {
        guard let node = configEntity.node else {
            dismiss()
            return
        }
        
        if !(streamingInfoUseCase?.isLocalHTTPProxyServerRunning() ?? true) {
            streamingInfoUseCase?.startServer()
        }
        
        guard
            let currentItem = configEntity.playerHandler.playerCurrentItem(),
            currentItem.node == node
        else {
            await initialize(with: node)
            return
        }
        configurePlayer()
        configEntity.playerHandler.resetCurrentItem(shouldResetPlayback: configEntity.playerType != .fileLink)
    }
    
    private func configurePlayer() {
        configEntity.playerHandler.addPlayer(listener: self)
        
        guard !configEntity.playerHandler.isPlayerEmpty(), let currentItem = configEntity.playerHandler.playerCurrentItem() else {
            router.dismiss()
            return
        }
        invokeCommand?(.initTracks(currentItem: currentItem, queue: configEntity.playerHandler.playerPlaylistItems(), loopMode: configEntity.playerHandler.currentRepeatMode() == .loop))
    }
    
    // MARK: - Node Init
    
    private nonisolated func initialize(with node: MEGANode) async {
        if configEntity.isFileLink {
            guard let track = streamingInfoUseCase?.info(from: node) else {
                await dismiss()
                return
            }
            await initialize(tracks: [track], currentTrack: track)
        } else {
            guard let children = configEntity.isFolderLink ? nodeInfoUseCase?.folderChildrenInfo(fromParentHandle: node.parentHandle) :
                                                nodeInfoUseCase?.childrenInfo(fromParentHandle: node.parentHandle),
                  let currentTrack = await children.async.first(where: { await $0.node?.handle == node.handle }) else {
                
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
    
    // MARK: - Offline Files Init
    
    private nonisolated func initialize(with offlineFilePaths: [String]) async {
        guard
            let files = offlineInfoUseCase?.info(from: offlineFilePaths),
            let currentFilePath = configEntity.fileLink,
            let currentTrack = await files.async.first(where: { await $0.url.path == currentFilePath })
        else {
            await dismiss()
            return
        }
        await initialize(tracks: files, currentTrack: currentTrack)
    }
    
    // MARK: - Private functions
    
    private nonisolated func initialize(tracks: [AudioPlayerItem], currentTrack: AudioPlayerItem) async {
        let mutableTracks = await shift(tracks: tracks, startItem: currentTrack)
        await resetConfigurationIfNeeded(nextCurrentTrack: currentTrack)
        configEntity.playerHandler.autoPlay(enable: configEntity.playerType != .fileLink)
        configEntity.playerHandler.addPlayer(tracks: mutableTracks)
        await configurePlayer()
    }

    private nonisolated func shift(tracks: [AudioPlayerItem], startItem: AudioPlayerItem) async -> [AudioPlayerItem] {
        guard tracks.contains(startItem) else { return tracks }
        return tracks.shifted(tracks.firstIndex(of: startItem) ?? 0)
    }
    
    private func resetConfigurationIfNeeded(nextCurrentTrack: AudioPlayerItem) async {
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
        configEntity.playerHandler.removePlayer(listener: self)
        
        streamingInfoUseCase?.stopServer()
        if configEntity.isFolderLink, !router.isAFolderLinkPresenter() {
            nodeInfoUseCase?.folderLinkLogout()
        }
        router.dismiss()
        
        Task { [audioPlayerUseCase] in
            await audioPlayerUseCase.unregisterMEGADelegate()
        }
    }
}

@MainActor
extension MiniPlayerViewModel: AudioPlayerObserversProtocol {
    nonisolated func audio(player: AVQueuePlayer, showLoading: Bool) {
        Task { @MainActor in
            invokeCommand?(.showLoading(showLoading))
        }
    }
    
    nonisolated func audio(player: AVQueuePlayer, currentTime: Double, remainingTime: Double, percentageCompleted: Float, isPlaying: Bool) {
        Task { @MainActor in
            if remainingTime > 0.0 { invokeCommand?(.showLoading(false)) }
            invokeCommand?(.reloadPlayerStatus(percentage: percentageCompleted, isPlaying: isPlaying))
        }
    }
    
    nonisolated func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, currentThumbnail: UIImage?) {
        Task { @MainActor in
            invokeCommand?(.reloadNodeInfo(thumbnail: currentThumbnail))
        }
    }
    
    nonisolated func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?, url: String) {
        Task { @MainActor in
            invokeCommand?(.reloadNodeInfo(thumbnail: thumbnail))
        }
    }
    
    nonisolated func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?) {
        Task { @MainActor in
            invokeCommand?(.reloadNodeInfo(thumbnail: thumbnail))
        }
    }
    
    nonisolated func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, indexPath: IndexPath?) {
        Task { @MainActor in
            guard let currentItem = currentItem, let indexPath = indexPath else { return }
            invokeCommand?(.change(currentItem: currentItem, indexPath: indexPath))
        }
    }
    
    nonisolated func audio(player: AVQueuePlayer, reload item: AudioPlayerItem?) {
        Task { @MainActor in
            guard let currentItem = item else { return }
            invokeCommand?(.reload(item: currentItem))
        }
    }
    
    nonisolated func audioPlayerWillStartBlockingAction() {
        Task { @MainActor in
            invokeCommand?(.enableUserInteraction(false))
        }
    }
    
    nonisolated func audioPlayerDidFinishBlockingAction() {
        Task { @MainActor in
            invokeCommand?(.enableUserInteraction(true))
        }
    }
    
    nonisolated func audioDidStartPlayingItem(_ item: AudioPlayerItem?) {
        Task { @MainActor in
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
            nodeList.isNotEmpty,
            let updatedNode = nodeList.first,
            configEntity.allNodes?.contains(where: { $0.handle == updatedNode.handle }) == true
        else {
            return
        }
        
        refreshItem(updatedNode.handle)
    }
    
    private func refreshItem(_ nodeHandle: HandleEntity) {
        guard let node = nodeInfoUseCase?.node(fromHandle: nodeHandle) else { return }
        
        configEntity.playerHandler.currentPlayer()?.refreshTrack(with: node)
        refreshItemUI(nodeHandle: nodeHandle)
    }
    
    private func refreshItemUI(nodeHandle: HandleEntity) {
        guard let currentPlayer = configEntity.playerHandler.currentPlayer(),
              let item = currentPlayer.tracks.first(where: { $0.node?.handle == nodeHandle }) else { return }
        
        invokeCommand?(.reload(item: item))
    }
}
