import Foundation
import AVFoundation

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
    
    //MARK: - Private properties
    private let assetQueue = DispatchQueue(label: "player.queue", qos: .utility)
    private let assetKeysRequiredToPlay = ["playable"]
    private var playerViewControllerKVOContext = 0
    private var timer: Timer?
    
    private var taskId: UIBackgroundTaskIdentifier?
  
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
    
    var currentThumbnail: UIImage? {
        currentItem()?.artwork
    }
    
    var currentNode: MEGANode? {
        currentItem()?.node
    }
    
    var currentTime: Double {
        guard let currentItem = queuePlayer?.currentItem, CMTimeGetSeconds(currentItem.currentTime()) > 0 else { return 0.0 }
        
        return CMTimeGetSeconds(currentItem.currentTime())
    }
    
    var currentDuration: Double {
        guard let currentItem = queuePlayer?.currentItem else { return 0.0 }
        
        return CMTimeGetSeconds(currentItem.duration)
    }
    
    var currentState: PlayerCurrentStateEntity? {
        PlayerCurrentStateEntity(currentTime: currentTime, remainingTime: duration - currentTime, percentage: percentageCompleted, isPlaying: isPlaying)
    }
    
    var rate: Float {
        get { queuePlayer?.rate ?? 0.0 }
        set { queuePlayer?.rate = newValue }
    }
    
    //MARK: - Private Computed Properties
    private var duration: Double {
        guard let currentItem = queuePlayer?.currentItem else { return 0.0 }
        
        return currentItem.duration.value == 0 ? 0.0 : CMTimeGetSeconds(currentItem.duration)
    }
    
    private var percentageCompleted: Float {
        currentTime == 0.0 || currentDuration == 0.0 ? 0.0 : Float(currentTime / currentDuration)
    }
    
    @objc var isPlaying: Bool {
        rate > Float(0.0)
    }
    
    @objc var isPaused: Bool = false
    
    var isAutoPlayEnabled: Bool = true
    var isAudioPlayerInterrupted: Bool = false
    
    //MARK: - Private Functions
    init(config: [PlayerConfiguration: Any]? = [.loop: false, .shuffle: false, .repeatOne: false]) {
        if let config = config { audioPlayerConfig = config }
    }
    
    deinit {
        queuePlayer = nil
        onClosePlayerCompletion?()
    }
    
    @objc func close(_ completion: @escaping () -> Void) {
        onClosePlayerCompletion = completion
        if isPlaying {
            pause()
        }
        unregisterAudioPlayerEvents()
        invalidateTimer()
        unregisterRemoteControls()
        unregisterAudioPlayerNotifications()
    }
    
    private func setupPlayer() {
        setAudioPlayerSession(active: true)
        
        queuePlayer = AVQueuePlayer(items: tracks)
        
        queuePlayer?.usesExternalPlaybackWhileExternalScreenIsActive = true
        queuePlayer?.volume = 1.0
        
        registerAudioPlayerEvents()
        registerRemoteControls()
        registerAudioPlayerNotifications()
        notify(aboutCurrentState)
        
        isAutoPlayEnabled ? play() : pause()
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
    
    func resetAudioSessionCategoryIfNeeded() {
        if AVAudioSession.sharedInstance().category != .playback {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
            } catch {
                MEGALogError("[AudioPlayer] AVAudioPlayerSession Error: \(error.localizedDescription)")
            }
        }
    }
    
    func add(tracks: [AudioPlayerItem]) {
        beginBackgroundTask()
        self.tracks = tracks
        setupPlayer()
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
        if listenerManager.listeners.filter({ $0 === listener }).isEmpty {
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
            $0.updateContentView(isPlaying ? 60: 0)
        }
    }
    
    func playerTracksContains(url: URL) -> Bool {
        tracks.compactMap{$0.url}
            .contains(url)
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
