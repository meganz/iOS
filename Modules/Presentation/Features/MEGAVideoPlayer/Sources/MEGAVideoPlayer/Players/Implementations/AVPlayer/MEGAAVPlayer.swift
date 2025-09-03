import AVFoundation
@preconcurrency import Combine

@MainActor
public final class MEGAAVPlayer {
    private let player = AVPlayer()
    private var playerLayer: AVPlayerLayer?
    private var _nodeName = ""

    private nonisolated(unsafe) var timeObserverToken: Any? {
        willSet { timeObserverToken.map(player.removeTimeObserver) }
    }

    private let stateSubject: CurrentValueSubject<PlaybackState, Never> = .init(.opening)
    private let currentTimeSubject: CurrentValueSubject<Duration, Never> = .init(.seconds(-1))
    private let durationSubject: CurrentValueSubject<Duration, Never> = .init(.seconds(-1))

    public let statePublisher: AnyPublisher<PlaybackState, Never>
    public let currentTimePublisher: AnyPublisher<Duration, Never>
    public let durationPublisher: AnyPublisher<Duration, Never>

    private nonisolated let debugMessageSubject = PassthroughSubject<String, Never>()

    private var isLoopEnabled: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private let streamingUseCase: any StreamingUseCaseProtocol
    private let notificationCenter: NotificationCenter

    init(
        streamingUseCase: some StreamingUseCaseProtocol,
        notificationCenter: NotificationCenter
    ) {
        self.streamingUseCase = streamingUseCase
        self.notificationCenter = notificationCenter
        self.statePublisher = stateSubject.eraseToAnyPublisher()
        self.currentTimePublisher = currentTimeSubject.eraseToAnyPublisher()
        self.durationPublisher = durationSubject.eraseToAnyPublisher()

        observePlayerTimeControlStatus()
        observePlayerPeriodicTime()
        observePlayerStatus()
    }

    deinit {
        timeObserverToken.map(player.removeTimeObserver)
    }
}

extension MEGAAVPlayer: PlayerOptionIdentifiable {
    public nonisolated var option: VideoPlayerOption { .avPlayer }
}

// MARK: - PlaybackStateObservable

extension MEGAAVPlayer: PlaybackStateObservable {
    public var state: PlaybackState {
        get { stateSubject.value }
        set { stateSubject.send(newValue) }
    }

    public var currentTime: Duration {
        get { currentTimeSubject.value }
        set { currentTimeSubject.send(newValue) }
    }

    public var duration: Duration {
        get { durationSubject.value }
        set { durationSubject.send(newValue) }
    }
}

// MARK: - PlaybackDebugMessageObservable

extension MEGAAVPlayer: PlaybackDebugMessageObservable {
    public nonisolated var debugMessagePublisher: AnyPublisher<String, Never> {
        debugMessageSubject.eraseToAnyPublisher()
    }

    public func playbackDebugMessage(_ message: String) {
        debugMessageSubject.send(message)
    }
}

// MARK: - PlaybackControllable

extension MEGAAVPlayer: PlaybackControllable {
    public func play() {
        player.play()
    }

    public func pause() {
        player.pause()
    }

    public func stop() {
        player.replaceCurrentItem(with: nil)
        streamingUseCase.stopStreaming()
    }

    public func jumpForward(by seconds: TimeInterval) {
        guard player.currentItem != nil else { return }
        let currentTime = player.currentTime()
        let newTime = currentTime.seconds + seconds
        seek(to: newTime)
    }

    public func jumpBackward(by seconds: TimeInterval) {
        guard player.currentItem != nil else { return }
        let currentTime = player.currentTime()
        let newTime = currentTime.seconds - seconds
        seek(to: max(newTime, 0))
    }

    public func seek(to time: TimeInterval) {
        // A timescale of 600 is recommended because it balances precision with efficiency
        // and has been the long-standing convention in Apple’s media frameworks.
        let newTime = CMTime(seconds: time, preferredTimescale: 600)
        guard newTime.isValid else { return }
        player.seek(to: newTime)
    }

    public func seek(to time: TimeInterval) async -> Bool {
        // A timescale of 600 is recommended because it balances precision with efficiency
        // and has been the long-standing convention in Apple’s media frameworks.
        let newTime = CMTime(seconds: time, preferredTimescale: 600)
        guard newTime.isValid else { return false }
        return await player.seek(to: newTime)
    }

    public func changeRate(to rate: Float) {
        player.rate = rate
    }
    
    public func setLooping(_ enabled: Bool) {
        isLoopEnabled = enabled
    }
}

// MARK: - VideoRenderable

extension MEGAAVPlayer: VideoRenderable {
    public func setupPlayer(in playerLayer: any PlayerLayerProtocol) {
        if let existingLayer = self.playerLayer {
            existingLayer.removeFromSuperlayer()
        }

        let newLayer = AVPlayerLayer(player: player)
        newLayer.frame = playerLayer.bounds
        newLayer.videoGravity = .resizeAspect
        playerLayer.layer.addSublayer(newLayer)
        self.playerLayer = newLayer
    }

    public func resizePlayer(to frame: CGRect) {
        playerLayer?.frame = frame
    }
    
    public func setScalingMode(_ mode: VideoScalingMode) {
        playerLayer?.videoGravity = mode.toAVLayerVideoGravity()
    }
}

// MARK: - NodeLoadable

extension MEGAAVPlayer: NodeLoadable {
    public func loadNode(_ node: some PlayableNode) {
        if !streamingUseCase.isStreaming {
            streamingUseCase.startStreaming()
        }

        guard let url = streamingUseCase.streamingLink(for: node) else {
            let errorMessage = "Failed to get streaming link for node"
            state = .error(errorMessage)
            playbackDebugMessage(errorMessage)
            return
        }

        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)

        observe(for: playerItem)

        _nodeName = node.nodeName
    }

    public var nodeName: String {
        _nodeName
    }

    private func observe(for playerItem: AVPlayerItem) {
        observePlaybackBufferStatus(for: playerItem)
        observeStatus(for: playerItem)
        observeDidPlayToEndTime(for: playerItem)
        observePlaybackStalledNotification(for: playerItem)
    }

    private func observePlaybackBufferStatus(for item: AVPlayerItem) {
        item.publisher(for: \.isPlaybackBufferEmpty, options: [.new])
            .filter { $0 }
            .sink { [weak self] _ in self?.willStartBuffering() }
            .store(in: &cancellables)

        item.publisher(for: \.isPlaybackLikelyToKeepUp, options: [.new])
            .filter { $0 }
            .sink { [weak self] _ in self?.willFinishBuffering() }
            .store(in: &cancellables)

        item.publisher(for: \.isPlaybackBufferFull, options: [.new])
            .filter { $0 }
            .sink { [weak self] _ in self?.willFinishBuffering() }
            .store(in: &cancellables)
    }

    private func willStartBuffering() {
        state = .buffering
    }

    private func willFinishBuffering() {
        timeControlStatusUpdated()
    }

    private func observeStatus(for item: AVPlayerItem) {
        item.publisher(for: \.status, options: [.initial, .new])
            .sink { [weak self] status in
                if status == .failed {
                    let errorMessage = "Player item failed with error: \(item.error?.localizedDescription ?? "Unknown error")"
                    self?.state = .error(errorMessage)
                    self?.playbackDebugMessage(errorMessage)
                }

                self?.playbackDebugMessage("Player item status changed to \(status.rawValue)")
            }
            .store(in: &cancellables)
    }

    private func observeDidPlayToEndTime(for item: AVPlayerItem) {
        notificationCenter
            .publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: item)
            .sink { [weak self] _ in self?.handlePlaybackEnded() }
            .store(in: &cancellables)
    }

    private func observePlaybackStalledNotification(for item: AVPlayerItem) {
        notificationCenter
            .publisher(for: AVPlayerItem.playbackStalledNotification, object: item)
            .sink { [weak self] _ in self?.willStartBuffering() }
            .store(in: &cancellables)
    }

    func handlePlaybackEnded() {
        if isLoopEnabled {
            seek(to: 0)
            play()
        } else {
            state = .ended
        }
    }
}

// MARK: - TimeObserver

extension MEGAAVPlayer {
    private func observePlayerPeriodicTime() {
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in self?.timeChanged(time) }
        }
    }

    private func timeChanged(_ newTime: CMTime) {
        updateCurrentTime(newTime)
        if let newDuration = player.currentItem?.duration {
            updateDuration(newDuration)
        }
    }

    private func updateCurrentTime(_ time: CMTime) {
        guard time.isValid, !(time.seconds.isNaN || time.seconds.isInfinite) else {
            playbackDebugMessage("Invalid time \(time)")
            return
        }

        currentTime = .seconds(time.seconds)
    }

    private func updateDuration(_ duration: CMTime) {
        guard duration.isValid, !(duration.seconds.isNaN || duration.seconds.isInfinite) else {
            playbackDebugMessage("Invalid duration \(duration)")
            return
        }

        let newDuration = Duration.seconds(duration.seconds)

        guard newDuration != self.duration else { return }

        self.duration = .seconds(duration.seconds)
    }
}

extension MEGAAVPlayer {
    private func observePlayerStatus() {
        player.publisher(for: \.status, options: [.initial, .new])
            .sink { [weak self] status in
                if status == .failed {
                    let errorMessage = self?.player.error?.localizedDescription ?? "Unknown player error"
                    self?.state = .error(errorMessage)
                    self?.playbackDebugMessage("Player failed: \(errorMessage)")
                }

                self?.playbackDebugMessage("Player status changed to \(status.rawValue)")
            }
            .store(in: &cancellables)
    }
}

extension MEGAAVPlayer {
    private func observePlayerTimeControlStatus() {
        player.publisher(for: \.timeControlStatus, options: [.initial, .new])
            .sink { [weak self] _ in self?.timeControlStatusUpdated() }
            .store(in: &cancellables)
    }

    private func timeControlStatusUpdated() {
        switch player.timeControlStatus {
        case .playing:
            state = .playing
        case .paused where state != .ended:
            state = .paused
        case .waitingToPlayAtSpecifiedRate:
            state = .buffering
        default:
            break
        }
    }
}

public extension MEGAAVPlayer {
    static func liveValue(
        node: some PlayableNode
    ) -> MEGAAVPlayer {
        let player = MEGAAVPlayer.liveValue
        player.loadNode(node)
        return player
    }

    static var liveValue: MEGAAVPlayer {
        MEGAAVPlayer(
            streamingUseCase: DependencyInjection.streamingUseCase,
            notificationCenter: .default
        )
    }
}
