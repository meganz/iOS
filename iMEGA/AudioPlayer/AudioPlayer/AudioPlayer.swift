import AVFoundation
import Foundation
import MediaPlayer
import MEGADomain
import MEGAFoundation
import MEGASwift

enum PlayerConfiguration: String {
    case loop, shuffle, repeatOne
}

final class AudioPlayer: NSObject {
    // MARK: - Internal properties
    var mediaPlayerNowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    var mediaPlayerRemoteCommandCenter = MPRemoteCommandCenter.shared()
    var queuePlayer: AVQueuePlayer?
    var tracks: [AudioPlayerItem] = []
    var audioQueueObserver: NSKeyValueObservation?
    var audioQueueStatusObserver: NSKeyValueObservation?
    var audioQueueStallObserver: NSKeyValueObservation?
    var audioQueueWaitingObserver: NSKeyValueObservation?
    var audioQueueBufferEmptyObserver: NSKeyValueObservation?
    var audioQueueBufferAlmostThereObserver: NSKeyValueObservation?
    var audioQueueBufferFullObserver: NSKeyValueObservation?
    var audioQueueRateObserver: NSKeyValueObservation?
    var audioQueueNewItemObserver: NSKeyValueObservation?
    var audioQueueLoadedTimeRangesObserver: NSKeyValueObservation?
    var audioSeekFallbackObserver: NSKeyValueObservation?
    var metadataQueueFinishAllOperationsObserver: NSKeyValueObservation?
    var audioPlayerConfig: [PlayerConfiguration: Any] = [.loop: false, .shuffle: false]
    var listenerManager = ListenerManager<any AudioPlayerObserversProtocol>()
    var presenterListenerManager = ListenerManager<any AudioPlayerPresenterProtocol>()
    let preloadMetadataMaxItems = 3
    let defaultRewindInterval: TimeInterval = 15.0
    var itemToRepeat: AudioPlayerItem?
    var onClosePlayerCompletion: (() -> Void)?
    var isAutoPlayEnabled = true
    var isAudioPlayerInterrupted = false
    var isPaused = false
    var isCloseRequested = false
    var needToBeResumedAfterInterruption = false
    var resettingPlayback = false
    var isAudioPlayerBeingReset = false
    
    var previouslyPlayedItem: AudioPlayerItem?
    var isUserPreviouslyJustPlayedSameItem = false
    
    let queueLoader = AudioQueueLoader()
    
    var preloadMetadataTask: Task<Void, Never>?
    
    // MARK: - Private properties
    private var timer: Timer?
    @Atomic private var taskId: UIBackgroundTaskIdentifier?
    private let debouncer = Debouncer(delay: 1.0, dispatchQueue: DispatchQueue.global(qos: .userInteractive))
    
    // MARK: - Internal Computed Properties, intended for important UTs
    var currentIndex: Int? {
        queuePlayer?.items().firstIndex(where: { $0 as? AudioPlayerItem == currentItem() })
    }

    var currentName: String? {
        currentItem()?.name
    }
    
    var currentArtist: String? {
        currentItem()?.artist
    }
    
    var currentThumbnail: UIImage? {
        currentItem()?.artwork
    }
    
    var currentNode: MEGANode? {
        currentItem()?.node
    }
    
    var currentTime: Double {
        guard let currentItem = queuePlayer?.currentItem, currentItem.currentTime().isValid, CMTimeGetSeconds(currentItem.currentTime()) > 0 else { return 0.0 }
        
        return CMTimeGetSeconds(currentItem.currentTime())
    }
    
    var currentState: PlayerCurrentStateEntity? {
        PlayerCurrentStateEntity(currentTime: currentTime, remainingTime: duration > currentTime ? duration - currentTime: 0.0, percentage: percentageCompleted, isPlaying: isPlaying)
    }
    
    var rate: Float? {
        get { queuePlayer?.rate }
        set {
            guard let newValue = newValue else { return }
            if newValue == 0 { storedRate = queuePlayer?.rate }
            queuePlayer?.rate = newValue
        }
    }
    
    var storedRate: Float?
    
    var isPlaying: Bool {
        guard let rate = rate else { return false }
        return rate > Float(0.0)
    }
    
    var isAlive: Bool {
        (isPlaying || isPaused) && !isCloseRequested
    }
    
    var duration: Double {
        guard let currentItem = queuePlayer?.currentItem, currentItem.duration.isValid else { return 0.0 }
        
        return currentItem.duration.value == 0 ? 0.0 : CMTimeGetSeconds(currentItem.duration)
    }
    
    // MARK: - Private Computed Properties
    
    private var percentageCompleted: Float {
        currentTime == 0.0 || duration == 0.0 ? 0.0 : Float(currentTime / duration)
    }
    
    // MARK: - Private Functions
    init(config: [PlayerConfiguration: Any]? = [.loop: false, .shuffle: false, .repeatOne: false]) {
        if let config = config { audioPlayerConfig = config }
        
        super.init()
        queueLoader.delegate = self
    }
    
    deinit {
        MEGALogDebug("[AudioPlayer] destroying audio player instance")
        queuePlayer = nil
        onClosePlayerCompletion?()
    }
    
    @objc func close(_ completion: @escaping () -> Void) {
        onClosePlayerCompletion = completion
        isCloseRequested = true
        if isPlaying {
            pause()
        }
        unregister()
        
        preloadMetadataTask?.cancel()
    }
    
    private func unregister() {
        invalidateTimer()
        unregisterAudioPlayerEvents()
        unregisterRemoteControls()
        unregisterAudioPlayerNotifications()
    }
    
    private func register() {
        registerAudioPlayerEvents()
        registerRemoteControls()
        registerAudioPlayerNotifications()
    }
    
    private func setupPlayer() {
        setAudioPlayerSession(active: true)
        
        queuePlayer = AVQueuePlayer(items: tracks)
        queuePlayer?.usesExternalPlaybackWhileExternalScreenIsActive = true
        queuePlayer?.volume = 1.0
        
        register()
        configurePlayer()
    }
    
    private func refreshPlayer(tracks: [AudioPlayerItem]) {
        notify(aboutTheBeginningOfBlockingAction)
        unregister()
        
        debouncer.start { [weak self] in
            guard let self else { return }
            
            self.tracks = tracks
            audioPlayerConfig = [.loop: false, .shuffle: false, .repeatOne: false]
            pause()
            
            if let newFirst = tracks.first {
                secureReplaceCurrentItem(with: newFirst)
            }
            
            self.queuePlayer?.items().lazy.filter({$0 != self.queuePlayer?.items().first}).forEach {
                self.queuePlayer?.remove($0)
            }
            self.tracks.forEach { self.queuePlayer?.secureInsert($0, after: self.queuePlayer?.items().last) }
            
            self.register()
            
            self.configurePlayer()
            self.notify(self.aboutTheEndOfBlockingAction)
        }
    }
    
    func onItemFinishedPlaying() {
        guard !isCloseRequested else { return }
        
        queueLoader.refillQueueIfNeeded()
    }
    
    private func configurePlayer() {
        isAutoPlayEnabled ? play() : pause()
        
        preloadNextTracksMetadata()
    }
    
    private func beginBackgroundTask() {
        endBackgroundTask()
        let taskId = UIApplication.shared.beginBackgroundTask(withName: "com.mega.audioPlayer.backgroundTask", expirationHandler: {
            self.endBackgroundTask()
        })
        self.$taskId.mutate { $0 = taskId }
    }
    
    private func endBackgroundTask() {
        guard let taskId, taskId != .invalid else { return }
        UIApplication.shared.endBackgroundTask(taskId)
        self.$taskId.mutate { $0 = .invalid }
    }
    
    private func secureReplaceCurrentItem(with item: AudioPlayerItem?) {
        guard let newItem = item else { return }
        
        self.queuePlayer?.items().filter({$0 == newItem}).forEach {
            self.queuePlayer?.remove($0)
        }
        
        self.queuePlayer?.replaceCurrentItem(with: newItem)
    }

    // MARK: - Internal Functions
    func setAudioPlayerSession(active: Bool) {
        resetAudioSessionCategoryIfNeeded()
        setAudioSession(active: active)
    }
    
    func setAudioSession(active: Bool) {
        do {
            try active ? AVAudioSession.sharedInstance().setActive(active) :
                        AVAudioSession.sharedInstance().setActive(active, options: .notifyOthersOnDeactivation)
        } catch {
            MEGALogError("[AudioPlayer] AVAudioSession Error: \(error.localizedDescription)")
        }
    }
    
    func setAudioPlayer(interrupted: Bool, needToBeResumed: Bool) {
        isAudioPlayerInterrupted = interrupted
        needToBeResumedAfterInterruption = needToBeResumed
    }
    
    func resetAudioSessionCategoryIfNeeded() {
        if AVAudioSession.sharedInstance().category != .playback || AVAudioSession.sharedInstance().categoryOptions.contains(.mixWithOthers) {
            AudioSessionUseCase.default.configureAudioPlayerAudioSession()
        }
    }
    
    func add(tracks: [AudioPlayerItem]) {
        beginBackgroundTask()
        self.tracks = queueLoader.addAllTracks(tracks)
        
        if queuePlayer != nil {
            queueLoader.reset()
            refreshPlayer(tracks: self.tracks)
            MEGALogDebug("[AudioPlayer] Refresh the current audio player")
        } else {
            setupPlayer()
            MEGALogDebug("[AudioPlayer] Setting up a new audio player")
        }
        
        notify(aboutAudioPlayerDidAddTracks)
    }
    
    func update(tracks: [AudioPlayerItem]) {
        self.tracks = tracks
    }
    
    @objc func currentItem() -> AudioPlayerItem? {
        queuePlayer?.currentItem as? AudioPlayerItem
    }
    
    @objc func queueItems() -> [AudioPlayerItem]? {
        guard let playerItems = queuePlayer?.items() as? [AudioPlayerItem] else { return nil }
        
        return playerItems.filter { $0 != currentItem() }
    }
    
    @objc func add(listener: any AudioPlayerObserversProtocol) {
        if listenerManager.listeners.notContains(where: { $0 === listener }) {
            listenerManager.add(listener)
        }
    }
    
    @objc func remove(listener: any AudioPlayerObserversProtocol) {
        listenerManager.remove(listener)
    }
    
    func removeAllListeners() {
        listenerManager.listeners.removeAll()
    }
    
    @objc func add(presenterListener: any AudioPlayerPresenterProtocol) {
        presenterListenerManager.add(presenterListener)
    }
    
    @objc func remove(presenterListener: any AudioPlayerPresenterProtocol) {
        presenterListenerManager.remove(presenterListener)
    }
    
    func updateContentViews(newHeight: CGFloat) {
        presenterListenerManager.notify {
            $0.updateContentView(isAlive ? newHeight : 0)
        }
    }
    
    func updateContentViewsIgnorePlayerLifeCycle(showMiniPlayer: Bool, newHeight: CGFloat) {
        presenterListenerManager.notify {
            $0.updateContentView(showMiniPlayer ? newHeight: 0)
        }
    }
    
    func playerTracksContains(url: URL) -> Bool {
        tracks.compactMap { $0.url }
            .contains(url)
    }
    
    func refreshTrack(with node: MEGANode) {
        tracks = tracks.map { track in
            guard track.node?.handle == node.handle else { return track }
            let updatedTrack = track
            if let newName = node.name,
               !updatedTrack.nameUpdatedByMetadata {
                updatedTrack.name = newName
            }
            updatedTrack.node = node
            return updatedTrack
        }
    }
}

// MARK: - Audio Player Time Functions
extension AudioPlayer {
    func setTimer() {
        if timer != nil {
            invalidateTimer()
        }
        
        timer = Timer(timeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let `self` = self else { return }
            self.notify(self.aboutCurrentState)
        }
        endBackgroundTask()
        
        guard let timer = timer else { return }
        RunLoop.current.add(timer, forMode: .common)
    }
    
    func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
}

extension AudioPlayer: AudioQueueLoaderDelegate {
    func currentQueueCount() -> Int {
        queuePlayer?.items().count ?? 0
    }
    
    func insertBatchInQueue(_ items: [AudioPlayerItem]) {
        guard items.isNotEmpty else { return }
        tracks.append(contentsOf: items)
        
        if let lastItem = queuePlayer?.items().last {
            var anchor = lastItem
            for item in items {
                queuePlayer?.secureInsert(item, after: anchor)
                anchor = item
            }
        } else if let first = items.first {
            secureReplaceCurrentItem(with: first)
            var anchor = queuePlayer?.currentItem ?? first
            for item in items.dropFirst() {
                queuePlayer?.secureInsert(item, after: anchor)
                anchor = item
            }
        }
    }
}
