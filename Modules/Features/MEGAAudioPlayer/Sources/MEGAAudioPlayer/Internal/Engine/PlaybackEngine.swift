import AVFoundation
@preconcurrency import Combine
import Foundation

// MARK: - Protocol

@MainActor
protocol PlaybackEngineProtocol: AnyObject {
    var currentTime: TimeInterval { get }
    var duration: TimeInterval? { get }
    var currentTimePublisher: AnyPublisher<TimeInterval, Never> { get }
    var durationPublisher: AnyPublisher<TimeInterval?, Never> { get }
    var playbackStatusPublisher: AnyPublisher<PlaybackStatus, Never> { get }
    var playbackSpeedPublisher: AnyPublisher<Float, Never> { get }
    var playbackRatePublisher: AnyPublisher<Float, Never> { get }
    var didPlayToEndPublisher: AnyPublisher<Void, Never> { get }

    func play(url: URL)
    /// Detach the loaded item without ending the session — see the implementation.
    func unloadCurrentItem()
    func togglePlayPause()
    func pause()
    func setPlaybackSpeed(_ rate: Float)
    func seek(toSeconds: TimeInterval)
    /// Restart the current item from the beginning (used for repeat-one).
    func replay()
    func stop()
}

// MARK: - PlaybackEngine

/// Owns the single `AVPlayer` instance and exposes its state through Combine
/// publishers. Knows nothing about MEGA nodes, queues, shuffle / repeat,
/// remote-command center, or now-playing info.
@MainActor
final class PlaybackEngine {
    private let currentTimeSubject = CurrentValueSubject<TimeInterval, Never>(0)
    private let durationSubject = CurrentValueSubject<TimeInterval?, Never>(nil)
    private let playbackStatusSubject = CurrentValueSubject<PlaybackStatus, Never>(.idle)
    private let playbackSpeedSubject = CurrentValueSubject<Float, Never>(1)
    private let didPlayToEndSubject = PassthroughSubject<Void, Never>()

    private let player = AVPlayer()
    private let notificationCenter: NotificationCenter
    private var timeObserverToken: Any?
    private var rateObservation: NSKeyValueObservation?
    private var durationObservation: NSKeyValueObservation?
    private var endObservation: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    private var isPlaybackIntended = false
    private var isInterrupted = false

    /// Target of the in-flight seek
    private var pendingSeekTarget: TimeInterval?
    /// Identifies the latest seek, so a superseded one cannot open the gate early.
    private var seekGeneration = 0

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        observeTimeControlStatus()
        startPeriodicTimeObserver()
        observeAudioInterruption()
    }
    
    isolated deinit {
        if let timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
        }
    }
}

// MARK: - PlaybackEngineProtocol

extension PlaybackEngine: PlaybackEngineProtocol {
    var currentTime: TimeInterval {
        currentTimeSubject.value
    }

    var duration: TimeInterval? {
        durationSubject.value
    }

    var currentTimePublisher: AnyPublisher<TimeInterval, Never> {
        currentTimeSubject.eraseToAnyPublisher()
    }

    var durationPublisher: AnyPublisher<TimeInterval?, Never> {
        durationSubject.eraseToAnyPublisher()
    }

    var playbackStatusPublisher: AnyPublisher<PlaybackStatus, Never> {
        playbackStatusSubject.eraseToAnyPublisher()
    }

    var playbackSpeedPublisher: AnyPublisher<Float, Never> {
        playbackSpeedSubject.eraseToAnyPublisher()
    }

    var playbackRatePublisher: AnyPublisher<Float, Never> {
        player.publisher(for: \.rate, options: [.initial, .new])
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    var didPlayToEndPublisher: AnyPublisher<Void, Never> {
        didPlayToEndSubject.eraseToAnyPublisher()
    }
}

// MARK: - Playback Control

extension PlaybackEngine {
    func play(url: URL) {
        resetSeekGate()
        configureAudioSession()
        let item = AVPlayerItem(url: url)
        observeDuration(of: item)
        observeEnd(of: item)
        player.replaceCurrentItem(with: item)
        playbackStatusSubject.send(.loading)
        currentTimeSubject.send(0)
        durationSubject.send(nil)
        isPlaybackIntended = true
        player.play()
    }

    /// Detach whatever is loaded without ending the session
    func unloadCurrentItem() {
        endObservation = nil
        resetSeekGate()
        player.pause()
        player.replaceCurrentItem(with: nil)
        isPlaybackIntended = false
        currentTimeSubject.send(0)
        durationSubject.send(nil)
        playbackStatusSubject.send(.idle)
    }

    func replay() {
        performSeek(to: 0)
        isPlaybackIntended = true
        player.play()
    }

    func togglePlayPause() {
        if player.timeControlStatus == .playing {
            player.pause()
            isPlaybackIntended = false
        } else {
            player.play()
            isPlaybackIntended = true
        }
    }

    func pause() {
        player.pause()
        isPlaybackIntended = false
    }

    func seek(toSeconds seconds: TimeInterval) {
        guard let duration = durationSubject.value,
              duration.isFinite,
              duration > 0,
              seconds.isFinite,
              seconds >= 0 else { return }
        performSeek(to: max(0, min(seconds, duration)))
    }

    /// Publishes the target up front and closes the gate until the seek lands, so the
    /// progress bar moves straight there instead of flashing back to the old position.
    private func performSeek(to target: TimeInterval) {
        seekGeneration += 1
        let generation = seekGeneration
        pendingSeekTarget = target
        currentTimeSubject.send(target)

        // Issued synchronously, so a caller may act on the player right after — see
        // `replay()`, which relies on the seek being queued ahead of its `play()`.
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600)) { [weak self] _ in
            // Always fires, including for a superseded seek (`finished == false`), so
            // the gate cannot get stuck closed. The flag is ignored on purpose — only
            // the newest generation opens the gate. The callback queue is unspecified,
            // hence the hop.
            Task { @MainActor in
                guard let self, generation == self.seekGeneration else { return }
                self.pendingSeekTarget = nil
            }
        }
    }

    private func resetSeekGate() {
        seekGeneration += 1
        pendingSeekTarget = nil
    }

    func setPlaybackSpeed(_ rate: Float) {
        playbackSpeedSubject.send(rate)
        player.defaultRate = rate
        if player.rate != 0 {
            player.rate = rate
        }
    }

    func stop() {
        endObservation = nil
        player.pause()
        player.replaceCurrentItem(with: nil)
        setPlaybackSpeed(1)
        isPlaybackIntended = false
        isInterrupted = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        resetSeekGate()
        currentTimeSubject.send(0)
        durationSubject.send(nil)
        playbackStatusSubject.send(.idle)
    }
}

// MARK: - Audio Session

extension PlaybackEngine {
    /// `.playback` so audio continues with the screen locked and silences
    /// other apps. Full session lifecycle (interruptions, route changes,
    /// background activation) lands in the audio-session task.
    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
    }
}

// MARK: - Audio Interruption

extension PlaybackEngine {
    private func observeAudioInterruption() {
        notificationCenter.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleAudioInterruption(notification)
            }
            .store(in: &cancellables)
    }

    private func handleAudioInterruption(_ notification: Notification) {
        guard let type = Self.interruptionType(from: notification) else { return }

        switch type {
        case .began:
            handleInterruptionBegan()
        case .ended:
            handleInterruptionEnded(notification: notification)
        @unknown default:
            break
        }
    }

    private func handleInterruptionBegan() {
        isInterrupted = true
    }

    private func handleInterruptionEnded(notification: Notification) {
        guard isInterrupted else { return }
        isInterrupted = false

        guard isPlaybackIntended,
              Self.interruptionOptions(from: notification).contains(.shouldResume) else {
            return
        }

        player.play()
    }
}

// MARK: - Interruption Notification Parsing

/// Pure `userInfo` decoding — no player state involved, so it stays off the
/// main actor and is callable from any context.
extension PlaybackEngine {
    nonisolated static func interruptionType(from notification: Notification) -> AVAudioSession.InterruptionType? {
        notification.rawRepresentable(forKey: AVAudioSessionInterruptionTypeKey)
    }

    nonisolated static func interruptionOptions(from notification: Notification) -> AVAudioSession.InterruptionOptions {
        notification.rawRepresentable(forKey: AVAudioSessionInterruptionOptionKey) ?? []
    }
}

private extension Notification {
    /// Decodes a `UInt`-backed `RawRepresentable` (an enum such as
    /// `AVAudioSession.InterruptionType`, or an `OptionSet` such as
    /// `AVAudioSession.InterruptionOptions`) stored in `userInfo` under `key`.
    func rawRepresentable<T: RawRepresentable>(forKey key: String) -> T? where T.RawValue == UInt {
        (userInfo?[key] as? UInt).flatMap(T.init(rawValue:))
    }
}

// MARK: - Time Observer

extension PlaybackEngine {
    private func startPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            // Registered on `.main`, so this already runs main-actor-isolated
            MainActor.assumeIsolated {
                // While a seek is in flight the observer still reports the pre-seek
                // position — publishing it would flash the progress bar backwards.
                guard let self, self.pendingSeekTarget == nil else { return }
                self.currentTimeSubject.send(CMTimeGetSeconds(time))
            }
        }
    }
}

// MARK: - State Observation

extension PlaybackEngine {
    private func observeTimeControlStatus() {
        rateObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor in
                self?.publishCurrentStatus()
            }
        }
    }

    /// Reads the player rather than the observation that woke it. The hand-over is
    /// asynchronous, so a status captured while the outgoing track was still loaded
    /// would land on the incoming one; sampling here means what is published always
    /// describes whatever the player holds now
    func publishCurrentStatus() {
        playbackStatusSubject.send(
            Self.playbackStatus(from: player.timeControlStatus, isLoaded: player.currentItem != nil)
        )
    }

    /// The latest published status, for tests that drive the real observations.
    var currentStatusForTesting: PlaybackStatus {
        playbackStatusSubject.value
    }

    static func playbackStatus(
        from timeControlStatus: AVPlayer.TimeControlStatus,
        isLoaded: Bool
    ) -> PlaybackStatus {
        guard isLoaded else { return .idle }
        return switch timeControlStatus {
        case .paused: .paused
        case .waitingToPlayAtSpecifiedRate: .buffering
        case .playing: .playing
        @unknown default: .paused
        }
    }

    private func observeEnd(of item: AVPlayerItem) {
        let subject = didPlayToEndSubject
        endObservation = notificationCenter
            .publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: item)
            .receive(on: DispatchQueue.main)
            .sink { _ in subject.send(()) }
    }

    private func observeDuration(of item: AVPlayerItem) {
        durationObservation?.invalidate()
        durationObservation = item.observe(\.duration, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor in
                self?.publishCurrentDuration()
            }
        }
    }

    /// Reads the loaded item rather than the one that was observed
    func publishCurrentDuration() {
        let seconds = player.currentItem.map { CMTimeGetSeconds($0.duration) }
        durationSubject.send(seconds.flatMap { $0.isFinite && $0 > 0 ? $0 : nil })
    }
}
