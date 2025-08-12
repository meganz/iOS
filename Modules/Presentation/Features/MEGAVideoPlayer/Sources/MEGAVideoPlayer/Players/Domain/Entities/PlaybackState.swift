public enum PlaybackState: Equatable, Sendable {
    /// Playback is stopped and can't be resumed (e.g. dismissed or deallocated).
    case stopped
    /// Playback item has just been opened but hasn't started yet.
    case opening
    /// Playback has started.
    case playing
    /// Playback is currently paused and can be resumed.
    case paused
    /// Playback is temporarily stopped to buffer the next segment.
    case buffering
    /// Playback has reached the end of the video.
    case ended
    /// An error occurred during playback, with an associated error message.
    case error(String)
}
