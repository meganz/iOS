/// App-level entry point to the video player's lifecycle.
@MainActor
public enum MEGAVideoPlayerSession {
    /// Takes down the running Picture in Picture window, if any, and ends the playback it was keeping alive —
    /// for when that playback must not outlive the account, such as on logout.
    public static func stop() {
        VideoPlayerPictureInPictureSession.endRunningSession()
    }
}
