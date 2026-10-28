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
    /// The current track's duration read from the file, known before the player item is ready.
    var metadataDurationPublisher: AnyPublisher<TimeInterval?, Never> { get }
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
    case itemFailed(PlaybackItemFailure)
    /// The track was taken down
    case takenDown
    /// `playCurrent()` ran with nothing in the queue
    case queueEmpty

    var eventReason: String {
        switch self {
        case .urlUnresolved: "urlUnresolved"
        case .itemFailed(let failure): "itemFailed:\(failure.errorDetail)"
        case .takenDown: "takenDown"
        case .queueEmpty: "queueEmpty"
        }
    }

    /// `eventReason` followed by what the service knew when the attempt failed, capped as the error
    /// domain it carries can be any length
    func eventReason(in context: AudioPlaybackFailureContext) -> String {
        String((eventReason + context.suffix).prefix(Self.maxReasonLength))
    }

    private static let maxReasonLength = 500
}

/// What the service knows about a failed attempt that the engine cannot see
struct AudioPlaybackFailureContext: Equatable {
    /// Whether the track is read through the streaming server; `nil` when there was no track
    let needsStreamingServer: Bool?
    let isStreamingServerRunning: Bool
    /// Whether another player took playback over since the track started
    let wasInterrupted: Bool

    var suffix: String {
        var detail = ""
        if let needsStreamingServer { detail += "|stream=\(needsStreamingServer ? 1 : 0)" }
        detail += "|srv=\(isStreamingServerRunning ? 1 : 0)|intr=\(wasInterrupted ? 1 : 0)"
        return detail
    }
}

/// What a failed item tells about itself. The error's codes rather than its description, which is
/// localized to the device language and so cannot be grouped on.
struct PlaybackItemFailure: Equatable {
    struct ErrorCode: Equatable {
        let domain: String
        let code: Int
    }

    /// Where the item was being read from when the error names an address
    enum Host: String, Equatable {
        /// The device itself — the SDK's streaming server
        case local
        /// Anywhere else, such as the address AirPlay rewrites the stream to
        case remote
    }

    /// `nil` when the item failed without an error
    let error: ErrorCode?
    /// The error the item's error wraps — for an AVFoundation failure, the one that names the cause
    let underlyingError: ErrorCode?
    /// `nil` when neither error names the address that failed
    let host: Host?
    let isAirPlayActive: Bool
    /// Where playback was when the item failed, in seconds — `0` for an item that failed to start
    let position: TimeInterval
    /// `nil` while the item had not reported one yet
    let duration: TimeInterval?

    var errorDetail: String {
        var fields = [error.map(Self.format) ?? "none"]
        if let underlyingError { fields.append("u=\(Self.format(underlyingError))") }
        if let host { fields.append("host=\(host.rawValue)") }
        fields.append("airplay=\(isAirPlayActive ? 1 : 0)")
        fields.append("t=\(Int(position))/\(duration.map { String(Int($0)) } ?? "-")")
        return fields.joined(separator: "|")
    }

    private static func format(_ code: ErrorCode) -> String {
        "\(code.domain):\(code.code)"
    }
}

extension PlaybackItemFailure {
    init(error: (any Error)?, isAirPlayActive: Bool, position: TimeInterval, duration: TimeInterval?) {
        let error = error.map { $0 as NSError }
        let underlyingError = error?.userInfo[NSUnderlyingErrorKey] as? NSError
        self.init(
            error: error.map { ErrorCode(domain: $0.domain, code: $0.code) },
            underlyingError: underlyingError.map { ErrorCode(domain: $0.domain, code: $0.code) },
            host: (error?.failingURLHost ?? underlyingError?.failingURLHost).map(Host.init(hostName:)),
            isAirPlayActive: isAirPlayActive,
            position: position,
            duration: duration
        )
    }
}

private extension PlaybackItemFailure.Host {
    init(hostName: String) {
        self = ["127.0.0.1", "localhost", "::1"].contains(hostName.lowercased()) ? .local : .remote
    }
}

private extension NSError {
    /// Only the host is read: the rest of the address identifies the file
    var failingURLHost: String? {
        let url = userInfo[NSURLErrorFailingURLErrorKey] as? URL
            ?? (userInfo[NSURLErrorFailingURLStringErrorKey] as? String).flatMap(URL.init(string:))
        return url?.host()
    }
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
