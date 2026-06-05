import Foundation

/// App-level entry point to the playback session lifecycle.
@MainActor
public enum MEGAAudioPlayerSession {
    /// Ends the current playback session, if any. 
    public static func stop() {
        AudioPlaybackService.shared.stop()
    }
}
