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
    var observersListenerManager = ListenerManager<any AudioPlayerObserversProtocol>()
    let preloadMetadataMaxItems = 3
    let defaultRewindInterval: TimeInterval = 15.0
    var itemToRepeat: AudioPlayerItem?
    var onClosePlayerCompletion: (() -> Void)?
    var isAudioPlayerInterrupted = false
    var isPaused = false
    var isCloseRequested = false
    var needToBeResumedAfterInterruption = false
    var resettingPlayback = false
    var isAudioPlayerBeingReset = false
    /// Set to `true` during a manual drag movement to prevent stale callbacks from the player (which may carry an outdated progress value) from overwriting
    /// the slider’s thumb position. Once the pending programmatic update has been applied, this flag is reset to `false`.
    var isUpdatingProgress = false
    /// Set to `true` once the player’s first item has transitioned to .readyToPlay
    var hasCompletedInitialConfiguration = false
    
    var previouslyPlayedItem: AudioPlayerItem?
    var isUserPreviouslyJustPlayedSameItem = false
    
    let queueLoader = AudioQueueLoader()
    
    var preloadMetadataTask: Task<Void, Never>?
    
    // MARK: - Private properties
    private var timeObserver: AudioPlayerTimeObserver?
    private let timeObserverInterval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    
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
        preloadMetadataTask?.cancel()
        preloadMetadataTask = nil
        queueLoader.reset()
        endBackgroundTask()
        unregister()
        audioSeekFallbackObserver?.invalidate()
        metadataQueueFinishAllOperationsObserver?.invalidate()
        mediaPlayerNowPlayingInfoCenter.nowPlayingInfo = nil
        observersListenerManager.listeners.removeAll()
        queueLoader.delegate = nil
        queuePlayer?.removeAllItems()
        queuePlayer = nil
        onClosePlayerCompletion?()
        onClosePlayerCompletion = nil
        tracks.removeAll()
    }
    
    @objc func close(_ completion: @escaping () -> Void) {
        onClosePlayerCompletion = completion
        isCloseRequested = true
        if isPlaying {
            pause()
        }
        unregister()
        
        preloadMetadataTask?.cancel()
        preloadMetadataTask = nil
        endBackgroundTask()
    }
    
    private func unregister() {
        unregisterAudioPlayerEvents()
        unregisterRemoteControls()
        unregisterAudioPlayerNotifications()
    }
    
    private func register() {
        registerAudioPlayerEvents()
        registerRemoteControls()
        registerAudioPlayerNotifications()
        registerTimeObserver()
    }
    
    private func setupPlayer() {
        setAudioPlayerSession(active: true)
        
        queuePlayer = AVQueuePlayer()
        loadTracksIntoQueue(tracks)
        queuePlayer?.usesExternalPlaybackWhileExternalScreenIsActive = true
        queuePlayer?.volume = 1.0
    }
    
    private func timeObserverHandler() {
        if !isUpdatingProgress {
            notify(aboutCurrentState)
        }
    }
    
    private func loadTracksIntoQueue(_ tracks: [AudioPlayerItem]) {
        notify(aboutTheBeginningOfBlockingAction)
        unregister()
        
        debouncer.start { [weak self] in
            guard let self else { return }
            
            self.tracks = tracks
            audioPlayerConfig = [.loop: false, .shuffle: false, .repeatOne: false]
            hasCompletedInitialConfiguration = false
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
    
    func registerTimeObserver() {
        timeObserver = AudioPlayerTimeObserver(
            player: queuePlayer,
            interval: timeObserverInterval
        ) { [weak self] _ in
            self?.timeObserverHandler()
        }
    }
    
    func removeTimeObserver() {
        timeObserver = nil
    }
    
    func onItemFinishedPlaying() {
        guard !isCloseRequested else { return }
        
        queueLoader.refillQueueIfNeeded()
    }
    
    private func configurePlayer() {
        play()
        
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
            loadTracksIntoQueue(self.tracks)
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
    
    /// Returns the current audio player item.
    /// - Note: During the player’s initial configuration there is no track yet assigned to `currentItem`. In this case, we treat the first entry in
    ///   `tracks` as the current track, since it will become the player’s `currentItem` once configuration completes.
    /// - Returns:
    ///   - If `hasCompletedInitialConfiguration` is `true`, the item that `queuePlayer` is currently playing, or`nil` if there isn’t one.
    ///   - Otherwise, the first element of `tracks`, or `nil` if `tracks` is empty (The latter case should not occur, as the audio player always starts with tracks.).
    @objc func currentItem() -> AudioPlayerItem? {
        hasCompletedInitialConfiguration ? (queuePlayer?.currentItem as? AudioPlayerItem) : tracks.first
    }
    
    @objc func queueItems() -> [AudioPlayerItem]? {
        guard let playerItems = queuePlayer?.items() as? [AudioPlayerItem] else { return nil }
        
        return playerItems.filter { $0 != currentItem() }
    }
    
    @objc func configure(listener: any AudioPlayerObserversProtocol) {
        add(listener: listener)
        
        if shouldShowLoadingView() {
            notify(aboutShowingLoadingView)
        }
    }
    
    private func add(listener: any AudioPlayerObserversProtocol) {
        if observersListenerManager.listeners.notContains(where: { $0 === listener }) {
            observersListenerManager.add(listener)
        }
    }
    
    @objc func remove(listener: any AudioPlayerObserversProtocol) {
        observersListenerManager.remove(listener)
    }
    
    func removeAllListeners() {
        observersListenerManager.listeners.removeAll()
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
    
    /// Determines whether the loading view should be displayed based on the player’s current state. The loading view is shown in either of two scenarios:
    /// 1. Buffering to minimize stalls: The player is actively buffering to prevent underruns.
    /// 2. Awaiting initial playback: The player hasn’t yet attempted to load any media, so we show the loading UI before the very first playback attempt.
    func shouldShowLoadingView() -> Bool {
        let isBuffering = queuePlayer?.timeControlStatus == .waitingToPlayAtSpecifiedRate
            && queuePlayer?.reasonForWaitingToPlay == .toMinimizeStalls

        let isWaitingForInitialPlayback = queuePlayer?.status == .unknown /// status of the player is not yet known because it has not tried to load new media resources for playback.

        return isBuffering || isWaitingForInitialPlayback
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
