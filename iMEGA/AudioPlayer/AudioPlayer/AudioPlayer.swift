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
    var metadataQueueFinishAllOperationsObserver: NSKeyValueObservation?
    var audioPlayerConfig: [PlayerConfiguration: Any] = [.loop: false, .shuffle: false]
    var listenerManager = ListenerManager<AudioPlayerObserversProtocol>()
    var presenterListenerManager = ListenerManager<AudioPlayerPresenterProtocol>()
    let preloadMetadataMaxItems = 3
    var itemToRepeat: AudioPlayerItem?
    var opQueue = OperationQueue() {
        didSet {
            opQueue.qualityOfService = .background
            opQueue.maxConcurrentOperationCount = preloadMetadataMaxItems
        }
    }
    
    //MARK: - Private properties
    private let assetQueue = DispatchQueue(label: "player.queue", qos: .utility)
    private let assetKeysRequiredToPlay = ["playable"]
    private var playerViewControllerKVOContext = 0
    private var timer: Timer?
    
    private var taskId: UIBackgroundTaskIdentifier?
  
    //MARK: - Internal Computed Properties
    var currentIndex: Int? {
        queuePlayer?.items().firstIndex(where:{($0 as? AudioPlayerItem)?.node == currentItem()?.node})
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
        guard let currentItem = queuePlayer?.currentItem else { return 0.0 }
        
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
    
    @objc func close() {
        unregisterAudioPlayerEvents()
        invalidateTimer()
        unregisterRemoteControls()
        unregisterAudioPlayerNotifications()
        queuePlayer = nil
        setDefaultAudioSession()
    }
    
    private func setupPlayer() {
        setAudioSession(active: true)
        
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
    func setAudioSession(active: Bool) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(active)
        } catch {
            MEGALogError("[AudioPlayer] AVAudioPlayerSession Error: \(error.localizedDescription)")
        }
    }
    
    func setDefaultAudioSession() {
        do {
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers])
        try AVAudioSession.sharedInstance().setMode(.voiceChat)
        try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            MEGALogError("[AudioPlayer] Restore default AVAudioSession Error: \(error.localizedDescription)")
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
    
    func shuffleQueue() {
        guard var playerItems = queuePlayer?.items().filter({ $0 != currentItem() }) as? [AudioPlayerItem] else { return }
    
        playerItems.shuffle()
        
        var last = currentItem()
                    
        playerItems.forEach { item in
            guard let playerItem = queuePlayer?.items().first(where:{($0 as? AudioPlayerItem) == item}) as? AudioPlayerItem else { return }
            
            queuePlayer?.remove(playerItem)
            queuePlayer?.insert(playerItem, after: last)
            last = playerItem
        }
        
        if let items = queuePlayer?.items() as? [AudioPlayerItem] {
            update(tracks: items)
        }
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
}

extension AudioPlayer: AudioPlayerTimerProtocol {
    func setTimer() {
        if timer != nil {
            invalidateTimer()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let `self` = self else { return }
            self.notify(self.aboutCurrentState)
        }
        endBackgroundTask()
    }
    
    func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
}
