import Foundation

enum PlayerLoadingState: Equatable {
    case loading
    /// Resolved enough to draw the screen — artwork and duration are in — but
    /// still working towards its first frame, so the layout stays as it is at
    /// start-up and only the centre control shows the throbber.
    case ready
    /// Stalled part-way through a track. Only the centre control falls back to
    /// the throbber — the scrubber, the artwork and the surrounding controls all
    /// stay as they were, because the player has not returned to start-up.
    case buffering
    case playing
    case paused
}

extension PlayerLoadingState {
    /// `true` when the centre control is showing a play/pause icon rather than the
    /// throbber — the states in which there is something to toggle
    var isToggleEnabled: Bool {
        switch self {
        case .playing, .paused: true
        case .loading, .ready, .buffering: false
        }
    }
}

extension PlayerLoadingState {
    init(status: PlaybackStatus, hasStartedPlayback: Bool, isReady: Bool) {
        switch status {
        case .error:
            // Short-circuits the gate on purpose: a track that failed to resolve
            // will never report a duration or artwork, so deferring to `isReady`
            // would leave the throbber spinning forever.
            self = .paused
        case .idle, .loading:
            self = .loading
        case .buffering:
            // A stall before the first frame is still start-up, so it stays on the
            // start-up layout; only once the track has played does a stall become
            // the mid-track `.buffering`, which leaves the screen as it was.
            if hasStartedPlayback {
                self = .buffering
            } else {
                self = isReady ? .ready : .loading
            }
        case .playing:
            // Deliberately past the gate: artwork can take longer to parse than the
            // first frame takes to arrive, and a track the user can already hear has
            // to be one they can pause — `.loading` disables every control.
            self = .playing
        case .paused:
            // Having played counts as much as being ready: the screen is already
            // drawn, so a pause must not drop it back to start-up.
            self = (hasStartedPlayback || isReady) ? .paused : .loading
        }
    }
}
