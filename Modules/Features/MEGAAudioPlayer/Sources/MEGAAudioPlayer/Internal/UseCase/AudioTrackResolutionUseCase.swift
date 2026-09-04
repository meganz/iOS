import Foundation
import MEGADomain

// MARK: - Result

enum AudioURLResolution: Equatable {
    /// Playable, at this address.
    case resolved(URL)
    /// Taken down for a Terms of Service violation — must not be played.
    case takenDown
    /// No address could be built (node missing, folder-link authorization failed).
    case unresolved
}

// MARK: - Protocol

/// Playback admission: a track's address plus the checks it must pass before the
/// engine is allowed to play it.
@MainActor
protocol AudioTrackResolutionUseCaseProtocol {
    /// The verdict when it is already known without a round-trip — a track playing
    /// from a file on the device, one probed earlier this session, or one with no
    /// address at all. `nil` means ``resolve(_:)`` has to go and ask.
    func cachedResolution(for track: PlaybackTrack) -> AudioURLResolution?

    func resolve(_ track: PlaybackTrack) async -> AudioURLResolution

    /// Drops the session's takedown verdicts. Called when playback stops.
    func reset()
}

// MARK: - Implementation

@MainActor
final class AudioTrackResolutionUseCase: AudioTrackResolutionUseCaseProtocol {
    private let urlUseCase: any AudioTrackURLUseCaseProtocol
    private let availabilityRepository: any AudioNodeAvailabilityRepositoryProtocol

    /// Takedown verdicts established this session, keyed by track id. Scoped to
    /// the session on purpose: a verdict is server state, not a durable property
    /// of the file, so it must not outlive the queue it was taken for.
    private var verdicts: [String: Bool] = [:]

    init(
        urlUseCase: some AudioTrackURLUseCaseProtocol = AudioTrackURLUseCase(),
        availabilityRepository: some AudioNodeAvailabilityRepositoryProtocol = DependencyInjection.nodeAvailabilityRepository
    ) {
        self.urlUseCase = urlUseCase
        self.availabilityRepository = availabilityRepository
    }

    func cachedResolution(for track: PlaybackTrack) -> AudioURLResolution? {
        guard let url = urlUseCase.url(for: track) else { return .unresolved }
        guard !url.isFileURL else { return .resolved(url) }
        guard let isTakenDown = verdicts[track.id] else { return nil }
        return isTakenDown ? .takenDown : .resolved(url)
    }

    func resolve(_ track: PlaybackTrack) async -> AudioURLResolution {
        if let known = cachedResolution(for: track) { return known }
        guard let url = urlUseCase.url(for: track),
              let node = track.streamingNode else { return .unresolved }

        do {
            let isTakenDown = try await availabilityRepository.isTakenDown(node)
            verdicts[track.id] = isTakenDown
            return isTakenDown ? .takenDown : .resolved(url)
        } catch {
            // An inconclusive check must not block playback: the legacy player treats
            // a failed probe as "not taken down" and plays on, and a network blip
            // should not look like a takedown to the user. Nothing is recorded,
            // though — a guess must not be remembered as a verdict, or one offline
            // moment would exempt the track for the rest of the session.
            return .resolved(url)
        }
    }

    func reset() {
        verdicts.removeAll()
    }
}
