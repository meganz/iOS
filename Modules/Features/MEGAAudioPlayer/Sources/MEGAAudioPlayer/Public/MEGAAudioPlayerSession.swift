import Foundation

/// App-level entry point to the playback session lifecycle.
///
/// Deliberately free of any UI reference: the player screen observes this session through
/// `AudioPlayerViewModel` and dismisses itself when it ends, rather than being dismissed from here.
@MainActor
public enum MEGAAudioPlayerSession {
    /// Whether the session currently has a track loaded.
    public static var isActive: Bool {
        AudioPlaybackService.shared.currentSource != nil
    }

    /// Ends the current playback session, if any.
    public static func stop() {
        AudioPlaybackService.shared.stop()
    }

    /// Ends the playback session only when one is active.
    ///
    /// Prefer this over `stop()` outside logout: `stop()` also tears down the shared HTTP streaming server,
    /// which video streaming uses, so calling it with nothing playing has side effects well beyond audio.
    public static func endActiveSession() {
        guard isActive else { return }

        stop()
    }

    /// Notifies the playback session that the app is about to terminate.
    public static func appWillTerminate() {
        AudioPlaybackService.shared.appWillTerminate()
    }
}
