import AVFoundation
@preconcurrency import Combine
import Foundation

// MARK: - Protocol

@MainActor
protocol PlaybackEngineProtocol: AnyObject {
    var currentTimePublisher: AnyPublisher<TimeInterval, Never> { get }
    var durationPublisher: AnyPublisher<TimeInterval?, Never> { get }
    var playbackStatusPublisher: AnyPublisher<PlaybackStatus, Never> { get }

    func play(url: URL)
    func togglePlayPause()
    func seek(toFraction: Double)
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

    private let player = AVPlayer()
    private var timeObserverToken: Any?
    private var rateObservation: NSKeyValueObservation?
    private var durationObservation: NSKeyValueObservation?

    init() {
        observeTimeControlStatus()
        startPeriodicTimeObserver()
    }
    
    isolated deinit {
        if let timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
        }
    }
}

// MARK: - PlaybackEngineProtocol

extension PlaybackEngine: PlaybackEngineProtocol {
    var currentTimePublisher: AnyPublisher<TimeInterval, Never> {
        currentTimeSubject.eraseToAnyPublisher()
    }

    var durationPublisher: AnyPublisher<TimeInterval?, Never> {
        durationSubject.eraseToAnyPublisher()
    }

    var playbackStatusPublisher: AnyPublisher<PlaybackStatus, Never> {
        playbackStatusSubject.eraseToAnyPublisher()
    }
}

// MARK: - Playback Control

extension PlaybackEngine {
    func play(url: URL) {
        configureAudioSession()
        let item = AVPlayerItem(url: url)
        observeDuration(of: item)
        player.replaceCurrentItem(with: item)
        playbackStatusSubject.send(.buffering)
        currentTimeSubject.send(0)
        durationSubject.send(nil)
        player.play()
    }

    func togglePlayPause() {
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
    }

    /// Seek to a 0...1 fraction of the current item's duration. No-op if the
    /// item hasn't reported a finite duration yet (streaming load still in
    /// progress, or the source is a live stream).
    func seek(toFraction fraction: Double) {
        guard let duration = durationSubject.value,
              duration.isFinite,
              duration > 0 else { return }
        let target = max(0, min(1, fraction)) * duration
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600))
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
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
