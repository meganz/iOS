import AVFoundation
@preconcurrency import Combine

@MainActor
public final class MEGAAVPlayer {
    private let player = AVPlayer()
    private var playerLayer: AVPlayerLayer?

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

extension MEGAAVPlayer: PlaybackDebugMessageObservable {
    public nonisolated var debugMessagePublisher: AnyPublisher<String, Never> {
        debugMessageSubject.eraseToAnyPublisher()
    }

    public func playbackDebugMessage(_ message: String) {
        debugMessageSubject.send(message)
    }
}

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
        let newTime = CMTime(seconds: time, preferredTimescale: 600)
        guard newTime.isValid else { return }
        player.seek(to: newTime)
    }
}

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
}

extension MEGAAVPlayer: NodeLoadable {
    public func loadNode(_ node: any PlayableNode) {
        if !streamingUseCase.isStreaming {
            streamingUseCase.startStreaming()
        }

        guard let url = streamingUseCase.streamingLink(for: node) else { return }
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)

        observe(for: playerItem)
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
        let newStatus: PlaybackState? = {
            switch player.timeControlStatus {
            case .playing: return .playing
            case .paused: return .paused
            default: return nil
            }
        }()

        if let newStatus {
            state = newStatus
        }
    }

    private func observeStatus(for item: AVPlayerItem) {
        item.publisher(for: \.status, options: [.initial, .new])
            .sink { [weak self] in self?.playbackDebugMessage("Player item status changed to \($0.rawValue)") }
            .store(in: &cancellables)
    }

    private func observeDidPlayToEndTime(for item: AVPlayerItem) {
        notificationCenter
            .publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: item)
            .sink { [weak self] _ in self?.state = .ended }
            .store(in: &cancellables)
    }

    private func observePlaybackStalledNotification(for item: AVPlayerItem) {
        notificationCenter
            .publisher(for: AVPlayerItem.playbackStalledNotification, object: item)
            .sink { [weak self] _ in self?.willStartBuffering() }
            .store(in: &cancellables)
    }
}

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

        self.duration = .seconds(duration.seconds)
    }
}

extension MEGAAVPlayer {
    private func observePlayerStatus() {
        player.publisher(for: \.status, options: [.initial, .new])
            .sink { [weak self] in self?.playbackDebugMessage("Player status changed to \($0.rawValue)") }
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
        node: any PlayableNode
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
