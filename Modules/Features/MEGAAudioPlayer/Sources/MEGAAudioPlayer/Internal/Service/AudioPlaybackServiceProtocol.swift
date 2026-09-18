import Combine
import Foundation

typealias AudioPlaybackServiceProtocol = PlaybackStateObservable & PlaybackControllable

// MARK: - Protocols
@MainActor
protocol PlaybackStateObservable {
    var currentSource: PlaybackSource? { get }
    var currentQueue: PlaybackQueue { get }
    var title: String { get }
    var artist: String? { get }
    var artworkData: Data? { get }
    var status: PlaybackStatus { get }
    /// `true` once the current track has produced audio at least once. Tells a
    /// stall that interrupts playback apart from the wait before the first frame.
    var hasStartedPlayback: Bool { get }
    var artworkResolved: Bool { get }
    var isAirPlayActive: Bool { get }
    var repeatMode: RepeatMode { get }
    var sleepTimerState: SleepTimerState { get }
    var isShuffleOn: Bool { get }

    var currentSourcePublisher: AnyPublisher<PlaybackSource?, Never> { get }
    var currentQueuePublisher: AnyPublisher<PlaybackQueue, Never> { get }
    var titlePublisher: AnyPublisher<String, Never> { get }
    var artistPublisher: AnyPublisher<String?, Never> { get }
    var artworkDataPublisher: AnyPublisher<Data?, Never> { get }
    var durationPublisher: AnyPublisher<TimeInterval?, Never> { get }
    var currentTimePublisher: AnyPublisher<TimeInterval, Never> { get }
    var statusPublisher: AnyPublisher<PlaybackStatus, Never> { get }
    var hasStartedPlaybackPublisher: AnyPublisher<Bool, Never> { get }
    var artworkResolvedPublisher: AnyPublisher<Bool, Never> { get }
    var isAirPlayActivePublisher: AnyPublisher<Bool, Never> { get }
    var playbackSpeedPublisher: AnyPublisher<Float, Never> { get }
    var playbackRatePublisher: AnyPublisher<Float, Never> { get }
    var repeatModePublisher: AnyPublisher<RepeatMode, Never> { get }
    var sleepTimerStatePublisher: AnyPublisher<SleepTimerState, Never> { get }
    var isShuffleOnPublisher: AnyPublisher<Bool, Never> { get }
    var resumePromptPublisher: AnyPublisher<ResumePrompt?, Never> { get }

    /// Why the track the session is trying to play cannot be played, or `nil` when
    /// nothing is blocked.
    var playbackBlockedPublisher: AnyPublisher<PlaybackBlockedReason?, Never> { get }

    // MARK: Queries

    func metadata(forTrackID id: String) async -> AudioMetadata?
}

@MainActor
protocol PlaybackControllable {
    func play(source: PlaybackSource)
    func play(atIndex index: Int)
    func togglePlayPause()
    func setPlaybackSpeed(_ rate: Float)
    func seek(toSeconds seconds: TimeInterval)
    func playPrevious()
    func playNext()
    func move(from source: Int, toOffset destination: Int)
    func cycleRepeat()
    func startSleepTimer(after interval: TimeInterval)
    func startSleepTimerAtEndOfTrack()
    func cancelSleepTimer()
    func toggleShuffle()
    func stop()

    /// Take a track out of the queue, leaving whatever is playing untouched.
    /// - Returns: `true` when the track was removed, `false` when no track matched the ID or it is the one currently playing.
    @discardableResult
    func removeTrack(withID id: String) -> Bool

    func resumeFromPrompt()
    func restartFromPrompt()
}

// MARK: - Resume prompt

struct ResumePrompt: Equatable {
    let fileName: String
    let playbackTime: TimeInterval
}

// MARK: - Blocked playback

enum PlaybackBlockedReason: Equatable {
    /// The file was taken down for a Terms of Service violation.
    case takenDown
}

// MARK: - Status

/// Why a playback attempt failed
enum AudioPlaybackFailureReason: Equatable {
    /// The track resolved to no playable URL.
    case urlUnresolved
    /// `AVPlayerItem` reported `.failed` — the engine had a URL but could not play it.
    case itemFailed(reason: String?)
    /// The track was taken down
    case takenDown
    /// `playCurrent()` ran with nothing in the queue
    case queueEmpty

    var eventReason: String {
        switch self {
        case .urlUnresolved: "urlUnresolved"
        case .itemFailed(let reason): "itemFailed:\(Self.sanitized(reason) ?? Self.unknownError)"
        case .takenDown: "takenDown"
        case .queueEmpty: "queueEmpty"
        }
    }

    private static func sanitized(_ reason: String?) -> String? {
        guard let trimmed = reason?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxReasonLength))
    }

    private static let maxReasonLength = 200
    private static let unknownError = "Unknown error"
}

enum PlaybackStatus: Equatable {
    case idle
    /// The session is starting a track up: resolving its address and clearing
    /// the admission checks, before anything reaches the engine.
    case loading
    /// An item is loaded and waiting to produce audio — first buffering, a
    /// mid-track stall, or held before its first frame.
    case buffering
    case playing
    case paused
    case error(AudioPlaybackFailureReason)
}
