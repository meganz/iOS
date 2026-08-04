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
    private let playbackStatusSubject = CurrentValueSubject<PlaybackStatus, Never>(.loading)
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
        configureAudioSession()
        let item = AVPlayerItem(url: url)
        observeDuration(of: item)
        observeEnd(of: item)
        player.replaceCurrentItem(with: item)
        playbackStatusSubject.send(.buffering)
        currentTimeSubject.send(0)
        durationSubject.send(nil)
        isPlaybackIntended = true
        player.play()
    }

    func replay() {
        player.seek(to: .zero)
        currentTimeSubject.send(0)
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
        let target = max(0, min(seconds, duration))
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600))
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
        currentTimeSubject.send(0)
        durationSubject.send(nil)
        playbackStatusSubject.send(.paused)
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
        let subject = currentTimeSubject
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            subject.send(CMTimeGetSeconds(time))
        }
    }
}

// MARK: - State Observation

extension PlaybackEngine {
    private func observeTimeControlStatus() {
        let subject = playbackStatusSubject
        rateObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { player, _ in
            Task { @MainActor in
                let status = PlaybackEngine.playbackStatus(from: player.timeControlStatus)
                subject.send(status)
            }
        }
    }

    private static func playbackStatus(from timeControlStatus: AVPlayer.TimeControlStatus) -> PlaybackStatus {
        switch timeControlStatus {
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
        let subject = durationSubject
        durationObservation = item.observe(\.duration, options: [.initial, .new]) { item, _ in
            let seconds = CMTimeGetSeconds(item.duration)
            let value: TimeInterval? = (seconds.isFinite && seconds > 0) ? seconds : nil
            Task { @MainActor in
                subject.send(value)
            }
        }
    }
}
