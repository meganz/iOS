import AVFoundation
@preconcurrency import Combine
import Foundation
import MediaPlayer
import MEGADomain
import MEGAFoundation
import MEGASwift

enum PlayerConfiguration: String {
    case loop, shuffle, repeatOne
}

@MainActor
final class AudioPlayer: NSObject {
    // MARK: - Internal properties
    var mediaPlayerNowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    var mediaPlayerRemoteCommandCenter = MPRemoteCommandCenter.shared()
    var queuePlayer: AVQueuePlayer?
    var tracks: [AudioPlayerItem] = []
    var eventCancellables = Set<AnyCancellable>()
    var notificationCancellables = Set<AnyCancellable>()
    var audioPlayerConfig: [PlayerConfiguration: Any] = [.loop: false, .shuffle: false]
    let preloadMetadataMaxItems = 3
    let defaultRewindInterval: TimeInterval = 15.0
    var itemToRepeat: AudioPlayerItem?
    var isAudioPlayerInterrupted = false
    var isPaused = false
    var isCloseRequested = false
    var needToBeResumedAfterInterruption = false
    var resettingPlayback = false
    var isAudioPlayerBeingReset = false
    /// Set to `true` during a manual drag movement to prevent stale callbacks from the player (which may carry an outdated progress value) from overwriting
    /// the slider’s thumb position. Once the pending programmatic update has been applied, this flag is reset to `false`.
    var isUpdatingProgress = false
    /// Set to `true` after the first load/initial configuration finishes (i.e. the player’s first item reaches `.readyToPlay`).
    /// On the **first** transition from `false` → `true`, `notify(aboutTheEndOfBlockingAction)` is invoked to end the blocking state and re‑enable
    /// buttons and other UI controls.
    var hasCompletedInitialConfiguration = false {
        didSet {
            guard hasCompletedInitialConfiguration, oldValue == false else { return }
            notify(aboutTheEndOfBlockingAction)
        }
    }
    /// Set to `true` once `AudioPlayer` has released its resources. Checked in async callbacks (KVO, notifications, tasks) to avoid
    /// running code after teardown has started.
    var hasTornDown = false
    
    var previouslyPlayedItem: AudioPlayerItem?
    var isUserPreviouslyJustPlayedSameItem = false
    
    let queueLoader = AudioQueueLoader()
    
    var preloadMetadataTask: Task<Void, Never>?
    
    var changePlaybackPositionCommandTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    
    var updateNowPlayingInfoTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    
    // MARK: - Private properties
    private var timeObserver: AudioPlayerTimeObserver?
    private let timeObserverInterval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    
    @Atomic private var taskId: UIBackgroundTaskIdentifier?
    /// Stores all registered audio player observers in a thread-safe array. Access is synchronized with `@Atomic`, and observers are compared
    /// by identity using `ObjectIdentifier` to avoid duplicates. Observers conforming to `AudioPlayerObserversProtocol` are used by the
    /// full-screen player, the mini-player, and the playlist view models to react to player-related events such as playback state, queue changes, metadata updates, and
    /// error notifications.
    @Atomic var observers: [any AudioPlayerObserversProtocol] = []
    private let debouncer: Debouncer
    
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
    
    /// Upcoming items excluding the current one, wrapping around if looping is enabled.
    var upcomingPlaylist: [AudioPlayerItem] {
        guard let current = currentItem(),
              let idx = tracks.firstIndex(where: { $0 == current }) else {
            return []
        }
        
        var upcoming = Array(tracks[(idx + 1)...])
        
        /// If looping is on, append the tracks from the start up to (but not including) the current item
        if let loopAllowed = audioPlayerConfig[.loop] as? Bool, loopAllowed {
            let wrapAround = Array(tracks[..<idx])
            upcoming.append(contentsOf: wrapAround)
        }
        
        return upcoming
    }
    
    // MARK: - Private Computed Properties
    
    private var percentageCompleted: Float {
        currentTime == 0.0 || duration == 0.0 ? 0.0 : Float(currentTime / duration)
    }
    
    // MARK: - Private Functions
    init(config: [PlayerConfiguration: Any]? = [.loop: false, .shuffle: false, .repeatOne: false], debounceDelay: TimeInterval = 1.0) {
        if let config { audioPlayerConfig = config }
        
        debouncer = Debouncer(delay: debounceDelay, dispatchQueue: DispatchQueue.global(qos: .userInteractive))
        
        super.init()
        queueLoader.delegate = self
    }
    
    deinit {
        MEGALogDebug("[AudioPlayer] destroying audio player instance")
        preloadMetadataTask?.cancel()
        preloadMetadataTask = nil
        changePlaybackPositionCommandTask?.cancel()
        changePlaybackPositionCommandTask = nil
        updateNowPlayingInfoTask?.cancel()
        updateNowPlayingInfoTask = nil
    }
    
    private func releasePlaybackResources() {
        guard !hasTornDown else { return }
        hasTornDown = true

        queueLoader.reset()
        endBackgroundTask()
        unregister()
        mediaPlayerNowPlayingInfoCenter.nowPlayingInfo = nil
        removeAllListeners()
        queueLoader.delegate = nil
        queuePlayer?.removeAllItems()
        queuePlayer = nil
        tracks.removeAll()
    }
    
    func close(_ completion: @escaping () -> Void) {
        isCloseRequested = true
        if isPlaying { pause() }
        releasePlaybackResources()
        completion()
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
    
    private func setupPlayer(initialBatch: [AudioPlayerItem]) {
        setAudioPlayerSession(active: true)
        
        queuePlayer = AVQueuePlayer()
        loadTracksIntoQueue(initialBatch)
        queuePlayer?.usesExternalPlaybackWhileExternalScreenIsActive = true
        queuePlayer?.volume = 1.0
        
        hasTornDown = false
    }
    
    private func timeObserverHandler() {
        if !isUpdatingProgress {
            notify(aboutCurrentState)
        }
    }
    
    private func loadTracksIntoQueue(_ itemsToEnqueue: [AudioPlayerItem]) {
        notify(aboutTheBeginningOfBlockingAction)
        unregister()
        
        audioPlayerConfig = [.loop: false, .shuffle: false, .repeatOne: false]
        hasCompletedInitialConfiguration = false
        pause()
        
        if let newFirst = itemsToEnqueue.first {
            secureReplaceCurrentItem(with: newFirst)
        }
        
        queuePlayer?.items().lazy.dropFirst().forEach { queuePlayer?.remove($0) }
        
        itemsToEnqueue.dropFirst().forEach { queuePlayer?.secureInsert($0, after: queuePlayer?.items().last) }
        
        register()
        
        configurePlayer()
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
        self.tracks = tracks
        queueLoader.reset()
        let initialBatch = queueLoader.addAllTracks(tracks)
        
        debouncer.start { @MainActor [weak self] in
            guard let self else { return  }
            
            if queuePlayer != nil {
                loadTracksIntoQueue(initialBatch)
                MEGALogDebug("[AudioPlayer] Refresh the current audio player")
            } else {
                setupPlayer(initialBatch: initialBatch)
                MEGALogDebug("[AudioPlayer] Setting up a new audio player")
            }
            
            notify(aboutAudioPlayerDidAddTracks)
        }
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
    func currentItem() -> AudioPlayerItem? {
        hasCompletedInitialConfiguration ? (queuePlayer?.currentItem as? AudioPlayerItem) : tracks.first
    }
    
    func queueItems() -> [AudioPlayerItem]? {
        guard let playerItems = queuePlayer?.items() as? [AudioPlayerItem] else { return nil }
        
        return playerItems.filter { $0 != currentItem() }
    }
    
    func configure(listener: any AudioPlayerObserversProtocol) {
        add(listener: listener)
        
        if shouldShowLoadingView() {
            notify(aboutShowingLoadingView)
        }
    }
    
    private func add(listener: any AudioPlayerObserversProtocol) {
        $observers.mutate { arr in
            let exists = arr.contains { ObjectIdentifier($0) == ObjectIdentifier(listener) }
            if !exists { arr.append(listener) }
        }
    }
    
    func remove(listener: any AudioPlayerObserversProtocol) {
        $observers.mutate { arr in
            arr.removeAll { ObjectIdentifier($0) == ObjectIdentifier(listener) }
        }
    }
    
    func removeAllListeners() {
        $observers.mutate { $0.removeAll() }
    }
    
    func notifyObservers(_ closure: (any AudioPlayerObserversProtocol) -> Void) {
        observers.forEach(closure)
    }
    
    func observerSnapshot() -> [any AudioPlayerObserversProtocol] { observers }
    
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
        
        /// The new batch has been enqueued; now preload metadata for those newly added items. `preloadNextTracksMetadata` reads
        /// from `queuePlayer.items()` and filters out already-loaded metadata, so it will pick up only the just-inserted tracks (or any other
        /// enqueued items lacking metadata), keeping work bounded to imminent playback.
        preloadNextTracksMetadata()
    }
}
