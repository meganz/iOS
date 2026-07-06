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
    var hasPlayedOnceBefore: Bool { get }
    var artworkResolved: Bool { get }
    var isAirPlayActive: Bool { get }

    var currentSourcePublisher: AnyPublisher<PlaybackSource?, Never> { get }
    var currentQueuePublisher: AnyPublisher<PlaybackQueue, Never> { get }
    var titlePublisher: AnyPublisher<String, Never> { get }
    var artistPublisher: AnyPublisher<String?, Never> { get }
    var artworkDataPublisher: AnyPublisher<Data?, Never> { get }
    var durationPublisher: AnyPublisher<TimeInterval?, Never> { get }
    var currentTimePublisher: AnyPublisher<TimeInterval, Never> { get }
    var statusPublisher: AnyPublisher<PlaybackStatus, Never> { get }
    var hasPlayedOnceBeforePublisher: AnyPublisher<Bool, Never> { get }
    var artworkResolvedPublisher: AnyPublisher<Bool, Never> { get }
    var isAirPlayActivePublisher: AnyPublisher<Bool, Never> { get }
    var playbackSpeedPublisher: AnyPublisher<Float, Never> { get }
}

@MainActor
protocol PlaybackControllable {
    func play(source: PlaybackSource)
    func togglePlayPause()
    func setPlaybackSpeed(_ rate: Float)
    func seek(toSeconds seconds: TimeInterval)
    func move(from source: Int, toOffset destination: Int)
    func stop()
}

// MARK: - Status

enum PlaybackStatus: Equatable {
    case loading
    case playing
    case paused
    case buffering
    case error(String)
}
