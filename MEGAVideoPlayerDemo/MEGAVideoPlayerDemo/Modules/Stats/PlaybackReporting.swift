import Foundation
import CoreGraphics

typealias PlaybackReporting = PlaybackSetupReporting
    & PlaybackStateReporting
    & InitialPlaybackTimingReporting
    & PlaybackStallReporting
    & PlaybackDebugReporting

protocol PlaybackSetupReporting {
    /// Reports the name of the playback player.
    ///
    /// This is used to identify the player instance in logs and analytics,
    /// which is essential for debugging and performance monitoring.
    func playbackPlayerOption(_ option: VideoPlayerOption)
}

protocol PlaybackStateReporting {
    /// Reports the current playback state.
    ///
    /// This is used to track changes in playback status, such as playing, paused, buffering, or ended,
    /// which is essential for understanding user interactions and playback flow.
    func playbackStateDidChange(_ state: PlaybackState)

    /// Reports the current playback time.
    ///
    /// This is crucial for tracking how far along the playback is,
    /// allowing for detailed analysis of user engagement and playback behavior.
    func playbackCurrentTimeDidChange(_ currentTime: Duration)
}

protocol InitialPlaybackTimingReporting {
    /// Reports the timestamp when playback is requested.
    ///
    /// Tracking the initial playback request time helps measure the delay before playback actually begins,
    /// allowing for analysis and optimization of startup latency.
    func playbackRequested()

    /// Reports the timestamp when playback actually starts.
    ///
    /// Capturing the exact start time of playback enables calculation of startup latency,
    /// which is critical for improving user experience by minimizing delays.
    func playbackStarted()
}

protocol PlaybackStallReporting {
    /// Reports the start of a stalling event.
    ///
    /// Called when playback has not progressed for a detectable period, indicating potential buffering or network-related delay.
    func playbackStallStarted()

    /// Reports the end of a stalling event.
    ///
    /// Called when playback resumes after a stall, helping measure the duration of stalling and assess playback stability.
    func playbackStallEnded()
}

protocol PlaybackDebugReporting {
    /// Reports a debug message related to playback.
    ///
    /// This is used for logging detailed information about playback events,
    func playbackDebugMessage(_ message: String)
}
