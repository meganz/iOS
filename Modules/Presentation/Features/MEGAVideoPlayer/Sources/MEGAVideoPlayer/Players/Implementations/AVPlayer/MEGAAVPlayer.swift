import AVFoundation
import AVKit
@preconcurrency import Combine
import MEGASdk
import UIKit

@MainActor
public final class MEGAAVPlayer {
    private let player = AVPlayer()
    private var playerLayer: AVPlayerLayer?
    public var currentNode: (any PlayableNode)?
    private var nodes: [any PlayableNode]?

    private nonisolated(unsafe) var timeObserverToken: Any? {
        willSet { timeObserverToken.map(player.removeTimeObserver) }
    }

    private let stateSubject: CurrentValueSubject<PlaybackState, Never> = .init(.opening)
    private let currentTimeSubject: CurrentValueSubject<Duration, Never> = .init(.seconds(-1))
    private let durationSubject: CurrentValueSubject<Duration, Never> = .init(.seconds(-1))
    private let canPlayNextSubject: CurrentValueSubject<Bool, Never> = .init(false)
    private let nodeNameSubject: CurrentValueSubject<String, Never> = .init("")

    public let statePublisher: AnyPublisher<PlaybackState, Never>
    public let currentTimePublisher: AnyPublisher<Duration, Never>
    public let durationPublisher: AnyPublisher<Duration, Never>
    public let canPlayNextPublisher: AnyPublisher<Bool, Never>
    public let nodeNamePublisher: AnyPublisher<String, Never>

    private nonisolated let debugMessageSubject = PassthroughSubject<String, Never>()

    private var isLoopEnabled: Bool = false
    private var playerRate: Float = 1.0

    private var cancellables = Set<AnyCancellable>()
    public var streamVideoNodesTask: Task<Void, Never>?

    private let streamingUseCase: any StreamingUseCaseProtocol
    private let notificationCenter: NotificationCenter
    private let resumePlaybackPositionUseCase: any ResumePlaybackPositionUseCaseProtocol
    private let videoNodesUseCase: any VideoNodesUseCaseProtocol

    public init(
        streamingUseCase: some StreamingUseCaseProtocol,
        notificationCenter: NotificationCenter,
        resumePlaybackPositionUseCase: some ResumePlaybackPositionUseCaseProtocol,
        videoNodesUseCase: some VideoNodesUseCaseProtocol
    ) {
        self.streamingUseCase = streamingUseCase
        self.notificationCenter = notificationCenter
        self.resumePlaybackPositionUseCase = resumePlaybackPositionUseCase
        self.videoNodesUseCase = videoNodesUseCase
        self.statePublisher = stateSubject.eraseToAnyPublisher()
        self.currentTimePublisher = currentTimeSubject.eraseToAnyPublisher()
        self.durationPublisher = durationSubject.eraseToAnyPublisher()
        self.canPlayNextPublisher = canPlayNextSubject.eraseToAnyPublisher()
        self.nodeNamePublisher = nodeNameSubject.eraseToAnyPublisher()

        observePlayerTimeControlStatus()
        observePlayerPeriodicTime()
        observePlayerStatus()
    }

    deinit {
        streamVideoNodesTask?.cancel()
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

    public var canPlayNext: Bool {
        get { canPlayNextSubject.value }
        set { canPlayNextSubject.send(newValue) }
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
        player.rate = playerRate
    }

    public func pause() {
        player.pause()
    }

    public func stop() {
        saveOrDeleteCurrentPosition()
        player.replaceCurrentItem(with: nil)
        timeObserverToken.map(player.removeTimeObserver)
        streamingUseCase.stopStreaming()
        streamVideoNodesTask?.cancel()
        streamVideoNodesTask = nil
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
        playerRate = rate
        if player.rate > 0 {
            player.rate = rate
        }
    }

    public func setLooping(_ enabled: Bool) {
        isLoopEnabled = enabled
    }

    public func playNext() {
        guard let currentNode,
              let nodes,
              let currentIndex = nodes.firstIndex(where: { $0.id == currentNode.id }) else { return }

        let nextIndex = currentIndex + 1
        guard nextIndex < nodes.count else { return }

        saveOrDeleteCurrentPosition()
        let nextNode = nodes[nextIndex]
        loadNode(nextNode)
        play()
        updateCanPlayNext()
    }

    public func playPrevious() {
        guard let currentNode,
              let nodes,
              let currentIndex = nodes.firstIndex(where: { $0.id == currentNode.id }) else { return }

        let previousIndex = currentIndex - 1
        guard previousIndex >= 0 else {
            seek(to: 0)
            return
        }

        saveOrDeleteCurrentPosition()
        let previousNode = nodes[previousIndex]
        loadNode(previousNode)
        play()
        updateCanPlayNext()
    }
}

// MARK: - VideoRenderable

extension MEGAAVPlayer: VideoRenderable {
    public func setupPlayer(in playerView: any PlayerViewProtocol) {
        if let existingLayer = self.playerLayer {
            existingLayer.removeFromSuperlayer()
        }

        let newLayer = AVPlayerLayer(player: player)
        newLayer.frame = playerView.bounds
        newLayer.videoGravity = .resizeAspect
        playerView.layer.addSublayer(newLayer)
        self.playerLayer = newLayer
    }

    public func resizePlayer(to frame: CGRect) {
        playerLayer?.frame = frame
    }
    
    public func setScalingMode(_ mode: VideoScalingMode) {
        playerLayer?.videoGravity = mode.toAVLayerVideoGravity()
    }

    public func captureSnapshot() async -> UIImage? {
        guard let asset = player.currentItem?.asset as? AVURLAsset,
              duration.components.seconds > 0 else {
            playbackDebugMessage("No video player asset or video player no initialized")
            return nil
        }

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero

        let time = player.currentTime()
        guard time.isValid, !time.seconds.isNaN, !time.seconds.isInfinite else {
            playbackDebugMessage("Invalid current time for snapshot: \(time)")
            return nil
        }

        do {
            let cgImage = try await imageGenerator.image(at: time).image
            let image = UIImage(cgImage: cgImage)
            playbackDebugMessage("Successfully captured snapshot at time: \(time.seconds)")
            return image
        } catch {
            playbackDebugMessage("Failed to capture snapshot: \(error.localizedDescription)")
            return nil
        }
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
        state = .opening
        currentTime = .seconds(-1)
        duration = .seconds(-1)
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)

        observe(for: playerItem)

        currentNode = node
        nodeName = currentNode?.nodeName ?? ""

        attemptResumeFromSavedPosition()
    }

    public var nodeName: String {
        get { nodeNameSubject.value }
        set { nodeNameSubject.send(newValue) }
    }

    public func streamVideoNodes(for node: some PlayableNode) {
        streamVideoNodesTask?.cancel()
        streamVideoNodesTask = Task { [weak self, videoNodesUseCase] in
            for await videoNodes in videoNodesUseCase.streamVideoNodes(for: node) {
                guard !Task.isCancelled else { return }
                self?.nodes = videoNodes
                if let currentNode = self?.currentNode,
                   let updatedCurrentNode = videoNodes.first(where: { $0.id == currentNode.id}) {
                    self?.currentNode = updatedCurrentNode
                    self?.nodeName = updatedCurrentNode.nodeName
                }
                self?.updateCanPlayNext()
            }
        }
    }

    private func updateCanPlayNext() {
        guard let currentNode,
              let nodes,
              let currentIndex = nodes.firstIndex(where: { $0.id == currentNode.id }) else {
            canPlayNext = false
            return
        }

        let nextIndex = currentIndex + 1
        guard nextIndex < nodes.count else {
            canPlayNext = false
            return
        }
        canPlayNext = true
    }

    private func attemptResumeFromSavedPosition() {
        guard let node = currentNode,
              let savedPosition = resumePlaybackPositionUseCase.getPlaybackPosition(for: node),
              savedPosition > 0 else {
            return
        }
        
        seek(to: savedPosition)
    }
    
    private func saveOrDeleteCurrentPosition() {
        guard let node = currentNode else {
            return
        }

        let minimumVideoResumePosition = 15
        let minimumVideoResumeDuration = 17
        if currentTime.components.seconds > minimumVideoResumePosition,
           duration.components.seconds > minimumVideoResumeDuration,
           currentTime.components.seconds < duration.components.seconds - 2 {
            let currentPosition = TimeInterval(currentTime.components.seconds)
            resumePlaybackPositionUseCase.savePlaybackPosition(currentPosition, for: node)
        } else {
            resumePlaybackPositionUseCase.deletePlaybackPosition(for: node)
        }
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

    private func handlePlaybackEnded() {
        if isLoopEnabled {
            seek(to: 0)
            play()
        } else {
            state = .ended
            if canPlayNext {
                playNext()
            }
        }
    }
}

// MARK: - PictureInPictureLoadable

extension MEGAAVPlayer: PictureInPictureLoadable {
    public func loadPIPController() -> AVPictureInPictureController? {
        guard AVPictureInPictureController.isPictureInPictureSupported(),
              let playerLayer else {
            return nil
        }

        let pipController = AVPictureInPictureController(playerLayer: playerLayer)
        pipController?.canStartPictureInPictureAutomaticallyFromInline = true
        return pipController
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
        let newDuration = Duration.seconds(time.seconds)
        if duration.components.seconds > 0 {
            currentTime = min(newDuration, duration)
        } else {
            currentTime = newDuration
        }
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
        node: any PlayableNode
    ) -> MEGAAVPlayer {
        let player = MEGAAVPlayer.liveValue
        player.loadNode(node)
        player.streamVideoNodes(for: node)
        return player
    }

    static var liveValue: MEGAAVPlayer {
        MEGAAVPlayer(
            streamingUseCase: DependencyInjection.streamingUseCase,
            notificationCenter: .default,
            resumePlaybackPositionUseCase: DependencyInjection.resumePlaybackPositionUseCase,
            videoNodesUseCase: DependencyInjection.videoNodesUseCase
        )
    }
}
