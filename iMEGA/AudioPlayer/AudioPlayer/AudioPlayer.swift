import Foundation
import AVFoundation
import MEGAFoundation
import MEGADomain

enum PlayerConfiguration: String {
    case loop, shuffle, repeatOne
}

final class AudioPlayer: NSObject {
    
    //MARK: - Internal properties
    var observers = [UIViewController]()
    var queuePlayer : AVQueuePlayer?
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
    var metadataQueueFinishAllOperationsObserver: NSKeyValueObservation?
    var audioPlayerConfig: [PlayerConfiguration: Any] = [.loop: false, .shuffle: false]
    var listenerManager = ListenerManager<AudioPlayerObserversProtocol>()
    var presenterListenerManager = ListenerManager<AudioPlayerPresenterProtocol>()
    let preloadMetadataMaxItems = 3
    let defaultRewindInterval: TimeInterval = 15.0
    var itemToRepeat: AudioPlayerItem?
    var opQueue = OperationQueue() {
        didSet {
            opQueue.qualityOfService = .background
            opQueue.maxConcurrentOperationCount = preloadMetadataMaxItems
        }
    }
    var onClosePlayerCompletion: (() -> Void)?
    var isAutoPlayEnabled = true
    var isAudioPlayerInterrupted = false
    var isPaused = false
    var isCloseRequested = false
    var needToBeResumedAfterInterruption = false
    
    //MARK: - Private properties
    private let assetQueue = DispatchQueue(label: "player.queue", qos: .utility)
    private let assetKeysRequiredToPlay = ["playable"]
    private var playerViewControllerKVOContext = 0
    private var timer: Timer?
    private var taskId: UIBackgroundTaskIdentifier?
    private let debouncer = Debouncer(delay: 1.0, dispatchQueue: DispatchQueue.global(qos: .userInteractive))
    
    //MARK: - Internal Computed Properties
    var currentIndex: Int? {
        queuePlayer?.items().firstIndex(where:{$0 as? AudioPlayerItem == currentItem()})
    }
    
    var currentName: String? {
        currentItem()?.name
    }
    
    var currentArtist: String? {
        currentItem()?.artist
    }
    
    var currentAlbum: String? {
        currentItem()?.album
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
    
    //MARK: - Private Computed Properties
    private var duration: Double {
        guard let currentItem = queuePlayer?.currentItem, currentItem.duration.isValid else { return 0.0 }
        
        return currentItem.duration.value == 0 ? 0.0 : CMTimeGetSeconds(currentItem.duration)
    }
    
    private var percentageCompleted: Float {
        currentTime == 0.0 || duration == 0.0 ? 0.0 : Float(currentTime / duration)
    }
    
    //MARK: - Private Functions
    init(config: [PlayerConfiguration: Any]? = [.loop: false, .shuffle: false, .repeatOne: false]) {
        if let config = config { audioPlayerConfig = config }
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
        opQueue.cancelAllOperations()
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
        queuePlayer?.actionAtItemEnd = .none
        queuePlayer?.usesExternalPlaybackWhileExternalScreenIsActive = true
        queuePlayer?.volume = 1.0
        
        register()
        
        configurePlayer()
    }
    
    private func refreshPlayer(tracks: [AudioPlayerItem]) {
        notify(aboutTheBeginningOfBlockingAction)
        unregister()
        
        debouncer.start { [weak self] in
            guard let `self` = self else { return }
            
            self.tracks = tracks
            self.audioPlayerConfig = [.loop: false, .shuffle: false, .repeatOne: false]
            self.pause()
            
            CrashlyticsLogger.log("[AudioPlayer] Player replaced Items: \(String(describing: self.queuePlayer?.items()))")
            self.secureReplaceCurrentItem(with: tracks.first)
            self.queuePlayer?.items().lazy.filter({$0 != self.queuePlayer?.items().first}).forEach {
                self.queuePlayer?.remove($0)
            }
            self.tracks.forEach { self.queuePlayer?.secureInsert($0, after: self.queuePlayer?.items().last) }
            
            CrashlyticsLogger.log("[AudioPlayer] Player new Items: \(String(describing: self.queuePlayer?.items()))")
            self.register()
            
            self.configurePlayer()
            self.notify(self.aboutTheEndOfBlockingAction)
        }
    }
    
    private func configurePlayer() {
        guard let currentItem = queuePlayer?.currentItem as? AudioPlayerItem else {
            return
        }
        if let startTime = currentItem.startTimeStamp {
            seekPlayerItem(currentItem, to: startTime)
        }
        
        isAutoPlayEnabled ? play() : pause()
        
        opQueue.cancelAllOperations()
        preloadNextTracksMetadata()
    }
    
    private func beginBackgroundTask() {
        taskId = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            self.endBackgroundTask()
        })
    }
    
    private func endBackgroundTask() {
        if self.taskId != .invalid {
            UIApplication.shared.endBackgroundTask(self.taskId ?? .invalid)
            self.taskId = .invalid
        }
    }
    
    private func secureReplaceCurrentItem(with item: AudioPlayerItem?) {
        guard let newItem = item else { return }
        
        self.queuePlayer?.items().filter({$0 == newItem}).forEach {
            CrashlyticsLogger.log("[AudioPlayer] Item removed: \(newItem)")
            self.queuePlayer?.remove($0)
        }
        
        self.queuePlayer?.replaceCurrentItem(with: newItem)
    }

    //MARK: - Internal Functions
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
        
        CrashlyticsLogger.log("[AudioPlayer] Previous instance exists: \(queuePlayer != nil)")
        
        if queuePlayer != nil {
            refreshPlayer(tracks: self.tracks)
            MEGALogDebug("[AudioPlayer] Refresh the current audio player")
        } else {
            setupPlayer()
            MEGALogDebug("[AudioPlayer] Setting up a new audio player")
        }
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
    
    @objc func add(listener: AudioPlayerObserversProtocol) {
        if listenerManager.listeners.notContains(where: { $0 === listener }) {
            listenerManager.add(listener)
        }
    }
    
    @objc func remove(listener: AudioPlayerObserversProtocol) {
        listenerManager.remove(listener)
    }
    
    @objc func add(presenterListener: AudioPlayerPresenterProtocol) {
        presenterListenerManager.add(presenterListener)
    }
    
    @objc func remove(presenterListener: AudioPlayerPresenterProtocol) {
        presenterListenerManager.remove(presenterListener)
    }
    
    func updateContentViews() {
        presenterListenerManager.notify {
            $0.updateContentView(isAlive ? 60: 0)
        }
    }
    
    func playerTracksContains(url: URL) -> Bool {
        tracks.compactMap{$0.url}
            .contains(url)
    }
    
    func seekPlayerItem( _ playerItem: AVPlayerItem, to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 1)
        if CMTIME_IS_VALID(cmTime)  {
            playerItem.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: nil)
        }
    }
    
}

extension AudioPlayer: AudioPlayerTimerProtocol {
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
