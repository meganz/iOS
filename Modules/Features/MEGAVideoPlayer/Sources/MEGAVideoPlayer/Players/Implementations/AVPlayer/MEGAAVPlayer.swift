import AVFoundation
import AVKit
@preconcurrency import Combine
import MEGADomain
import UIKit

@MainActor
public final class MEGAAVPlayer {
    private let player = AVPlayer()
    private var playerLayer: AVPlayerLayer?
    public var currentNode: (any PlayableNode)?
    private var nodes: [any PlayableNode]?

    private var currentURL: URL?

    private var timeObserverToken: Any?

    private let stateSubject: CurrentValueSubject<PlaybackState, Never> = .init(.opening)
    private let currentTimeSubject: CurrentValueSubject<Duration, Never> = .init(.seconds(-1))
    private let durationSubject: CurrentValueSubject<Duration, Never> = .init(.seconds(-1))
    private let canPlayNextSubject: CurrentValueSubject<Bool, Never> = .init(false)
    private let nodeNameSubject: CurrentValueSubject<String, Never> = .init("")
    private let bufferRangeSubject: CurrentValueSubject<(start: Duration, end: Duration)?, Never> = .init(nil)
    private let itemStatusSubject: CurrentValueSubject<AVPlayerItem.Status, Never> = .init(.unknown)
    private let isExternalPlaybackActiveSubject: CurrentValueSubject<Bool, Never> = .init(false)

    public let statePublisher: AnyPublisher<PlaybackState, Never>
    public let currentTimePublisher: AnyPublisher<Duration, Never>
    public let durationPublisher: AnyPublisher<Duration, Never>
    public let canPlayNextPublisher: AnyPublisher<Bool, Never>
    public let nodeNamePublisher: AnyPublisher<String, Never>
    public let bufferRangePublisher: AnyPublisher<(start: Duration, end: Duration)?, Never>
    public let itemStatusPublisher: AnyPublisher<AVPlayerItem.Status, Never>
    public let isExternalPlaybackActivePublisher: AnyPublisher<Bool, Never>

    public var onNodeDeleted: (() -> Void)?

    private nonisolated let debugMessageSubject = PassthroughSubject<String, Never>()

    private var isLoopEnabled: Bool = false
    private var playerRate: Float = 1.0

    private var cancellables = Set<AnyCancellable>()
    public var monitorVideoNodesUpdateTask: Task<Void, Never>?

    private var throttleRateCancellable: AnyCancellable?
    private var throttleConfigurationTask: Task<Void, Never>?

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
        self.bufferRangePublisher = bufferRangeSubject.eraseToAnyPublisher()
        self.itemStatusPublisher = itemStatusSubject.eraseToAnyPublisher()
        self.isExternalPlaybackActivePublisher = isExternalPlaybackActiveSubject.eraseToAnyPublisher()

        observePlayerTimeControlStatus()
        observePlayerPeriodicTime()
        observePlayerStatus()
        observeExternalPlayback()
    }

    deinit {
        monitorVideoNodesUpdateTask?.cancel()
        throttleConfigurationTask?.cancel()
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
        currentURL = nil
        player.replaceCurrentItem(with: nil)
        if let timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        resetThrottleBitrate()
        streamingUseCase.stopStreaming()
        monitorVideoNodesUpdateTask?.cancel()
        monitorVideoNodesUpdateTask = nil
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
        guard player.currentItem != nil else { return false }
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
              let currentIndex = nodes.firstIndex(where: { $0.handle == currentNode.handle }) else { return }

        let nextIndex = currentIndex + 1
        guard nextIndex < nodes.count else { return }

        saveOrDeleteCurrentPosition()
        let nextNode = nodes[nextIndex]
        playNode(nextNode)
        updateCanPlayNext()
    }

    public func playPrevious() {
        guard let currentNode,
              let nodes,
              let currentIndex = nodes.firstIndex(where: { $0.handle == currentNode.handle }) else { return }

        let previousIndex = currentIndex - 1
        guard previousIndex >= 0 else {
            seek(to: 0)
            return
        }

        saveOrDeleteCurrentPosition()
        let previousNode = nodes[previousIndex]
        playNode(previousNode)
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
    public func loadNodeAndMonitorUpdate(for node: some PlayableNode, monitor nodes: [some PlayableNode]) {
        self.nodes = nodes
        monitorVideoNodesUpdate(for: nodes)
        playNode(node)
        updateCanPlayNext()
    }

    public var nodeName: String {
        get { nodeNameSubject.value }
        set { nodeNameSubject.send(newValue) }
    }

    private func playNode(_ node: some PlayableNode) {
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
        currentURL = url
        let itemURL = player.isExternalPlaybackActive ? url.updatedURLWithCurrentAddress() : url
        let playerItem = AVPlayerItem(url: itemURL)
        player.replaceCurrentItem(with: playerItem)

        observe(for: playerItem)

        currentNode = node
        nodeName = currentNode?.name ?? ""

        attemptResumeFromSavedPosition()

        play()
    }

    /// Retries the current node after a playback failure. A failed `AVPlayerItem` is terminal — `play()`
    /// on it neither resumes nor issues another request — so the item is rebuilt from a freshly requested
    /// streaming link, and it is that request which raises the over-quota warning again.
    ///
    /// Mirrors `playNode(_:)`, but resumes where playback died rather than at the saved resume position,
    /// and keeps the node info already on screen.
    public func replayCurrentNode() {
        guard let node = currentNode else { return }

        let replayPosition = TimeInterval(currentTime.components.seconds)

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
        currentURL = url
        let itemURL = player.isExternalPlaybackActive ? url.updatedURLWithCurrentAddress() : url
        let playerItem = AVPlayerItem(url: itemURL)
        player.replaceCurrentItem(with: playerItem)

        observe(for: playerItem)

        if replayPosition > 0 {
            seek(to: replayPosition)
        }

        play()
    }

    private func monitorVideoNodesUpdate(for nodes: [some PlayableNode]) {
        monitorVideoNodesUpdateTask?.cancel()
        monitorVideoNodesUpdateTask = Task { [weak self, videoNodesUseCase] in
            for await videoNodes in await videoNodesUseCase.monitorVideoNodesUpdates(for: nodes) {
                guard !Task.isCancelled else { return }

                for videoNode in videoNodes {
                    guard let index = nodes.firstIndex(where: { $0.handle == videoNode.handle }) else {
                        continue
                    }
                    self?.nodes?[index] = videoNode
                    guard let currentNode = self?.currentNode else {
                        self?.onNodeDeleted?()
                        return
                    }
                    if currentNode.handle == self?.nodes?[index].handle {
                        self?.currentNode = videoNode
                        if videoNodesUseCase.isInRubbishBin(node: currentNode) {
                            self?.onNodeDeleted?()
                            return
                        } else {
                            self?.nodeName = self?.currentNode?.name ?? ""
                            self?.updateCanPlayNext()
                        }
                    }
                }
            }
        }
    }

    private func updateCanPlayNext() {
        guard let currentNode,
              let nodes,
              let currentIndex = nodes.firstIndex(where: { $0.handle == currentNode.handle }) else {
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
        // The previous item's throttle says nothing about this one; it is reinstalled once this
        // item reports its own bitrate in `configureThrottleBitrate(for:)`.
        resetThrottleBitrate()
        observePlaybackBufferStatus(for: playerItem)
        observeStatus(for: playerItem)
        observeDidPlayToEndTime(for: playerItem)
        observePlaybackStalledNotification(for: playerItem)
        observeBufferRange(for: playerItem)
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
                if status == .readyToPlay {
                    self?.configureThrottleBitrate(for: item)
                }
                self?.itemStatusSubject.send(status)
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
    
    private func observeBufferRange(for item: AVPlayerItem) {
        item.publisher(for: \.loadedTimeRanges, options: [.new])
            .sink { [weak self] timeRanges in
                self?.updateBufferRange(timeRanges)
            }
            .store(in: &cancellables)
    }
    
    private func updateBufferRange(_ timeRanges: [NSValue]) {
        guard let latestRange = timeRanges.last?.timeRangeValue else {
            bufferRangeSubject.send(nil)
            return
        }
        let bufferStartSeconds = CMTimeGetSeconds(latestRange.start)
        let bufferEndSeconds = CMTimeGetSeconds(CMTimeRangeGetEnd(latestRange))
        bufferRangeSubject.send(
            (start: .seconds(bufferStartSeconds), end: .seconds(bufferEndSeconds))
        )
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

// MARK: - Streaming throttle

extension MEGAAVPlayer {
    /// Throttles the streaming server to what this item actually needs to play.
    ///
    /// Left unthrottled, the server races ahead of playback for high-bitrate media and the audio
    /// track drops out. Once the item's own bitrate is known, a matching cap is installed and kept
    /// in sync with `AVPlayer.rate`, since faster playback consumes proportionally more bandwidth.
    ///
    /// - Parameter playerItem: The player item whose asset bitrate determines the throttle.
    private func configureThrottleBitrate(for playerItem: AVPlayerItem) {
        throttleConfigurationTask?.cancel()

        let asset = playerItem.asset

        throttleConfigurationTask = Task { [weak self] in
            do {
                let totalBitrate = try await Self.totalBitrate(of: asset)
                guard !Task.isCancelled, let self else { return }

                if streamingUseCase.updateThrottleBitrate(totalBitrate: totalBitrate, playbackRate: player.rate) {
                    bindPlayerRateForThrottle(totalBitrate: totalBitrate)
                    playbackDebugMessage("Throttle installed for bitrate \(totalBitrate) bps")
                } else {
                    throttleRateCancellable = nil
                    playbackDebugMessage("Not high bitrate: \(totalBitrate) bps, throttle not set")
                }
            } catch {
                self?.playbackDebugMessage("Failed to load tracks for throttle: \(error.localizedDescription)")
            }
        }
    }

    /// Combined estimated data rate of every audio and video track in the asset, in bits per second.
    private static func totalBitrate(of asset: AVAsset) async throws -> Float {
        var totalBitrate: Float = 0

        for mediaType in [AVMediaType.video, .audio] {
            for track in try await asset.loadTracks(withMediaType: mediaType) {
                totalBitrate += try await track.load(.estimatedDataRate)
            }
        }

        return totalBitrate
    }

    /// Re-applies the throttle whenever the playback rate changes, so a sped-up playback isn't
    /// starved by a cap sized for 1×. Only non-zero rates are forwarded, so pausing keeps the
    /// current cap rather than resetting it.
    private func bindPlayerRateForThrottle(totalBitrate: Float) {
        throttleRateCancellable = player.publisher(for: \.rate)
            .removeDuplicates()
            .filter { $0 > 0 }
            .sink { [weak self] rate in
                self?.streamingUseCase.updateThrottleBitrate(totalBitrate: totalBitrate, playbackRate: rate)
            }
    }

    /// Drops the throttle and everything keeping it up to date, so it doesn't outlive the item it
    /// was sized for.
    private func resetThrottleBitrate() {
        throttleConfigurationTask?.cancel()
        throttleConfigurationTask = nil
        throttleRateCancellable = nil
        streamingUseCase.resetThrottleBitrate()
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

// MARK: - External playback (AirPlay)

extension MEGAAVPlayer: ExternalPlaybackObservable {
    public var isExternalPlaybackActive: Bool {
        isExternalPlaybackActiveSubject.value
    }

    private func observeExternalPlayback() {
        player.publisher(for: \.isExternalPlaybackActive)
            .removeDuplicates()
            .scan((old: false, new: false)) { state, value in
                (old: state.new, new: value)
            }
            .dropFirst()
            .sink { [weak self] state in
                guard state.old != state.new else { return }
                guard let self else { return }
                playbackDebugMessage("External playback active: \(state.new)")
                let isPlaying = player.rate > 0
                player.pause()
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    replaceURLForExternalPlayback(activated: state.new)
                    updateExternalPlaybackState(activated: state.new)
                    if isPlaying {
                        player.play()
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func updateExternalPlaybackState(activated: Bool) {
        isExternalPlaybackActiveSubject.send(activated)
    }

    private func replaceURLForExternalPlayback(activated: Bool) {
        guard let currentURL else { return }
        let url = activated ? currentURL.updatedURLWithCurrentAddress() : currentURL
        replaceCurrentItemURL(to: url)
    }

    private func replaceCurrentItemURL(to url: URL) {
        playbackDebugMessage("Replacing player item url to: \(url)")
        let currentTime = player.currentTime()
        let newItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: newItem)
        observe(for: newItem)

        guard currentTime.isValid else { return }
        player.seek(to: currentTime)
    }
}

extension MEGAAVPlayer {
    private func observePlayerTimeControlStatus() {
        player.publisher(for: \.timeControlStatus, options: [.initial, .new])
            .sink { [weak self] _ in self?.timeControlStatusUpdated() }
            .store(in: &cancellables)
    }

    /// A failed item is terminal, so `.error` has to survive until a fresh item replaces it. The player
    /// keeps reporting time-control changes after the failure — parking on `.waitingToPlayAtSpecifiedRate`
    /// or `.paused` — which would otherwise replace `.error` with a spinner that never resolves and leave
    /// the user no play button to tap.
    private func timeControlStatusUpdated() {
        if case .error = state { return }
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
        for node: some PlayableNode,
        within videoNodes: [some PlayableNode]
    ) -> MEGAAVPlayer {
        let player = MEGAAVPlayer.liveValue
        player.loadNodeAndMonitorUpdate(for: node, monitor: videoNodes)
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
