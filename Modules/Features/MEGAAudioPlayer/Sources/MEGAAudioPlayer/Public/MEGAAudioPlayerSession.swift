import Foundation
import MEGADomain

/// App-level entry point to the playback session lifecycle.
///
/// Deliberately free of any UI reference: the player screen observes this session through
/// `AudioPlayerViewModel` and dismisses itself when it ends, rather than being dismissed from here.
@MainActor
public enum MEGAAudioPlayerSession {
    /// Ends the current playback session, if any.
    public static func stop() {
        AudioPlaybackService.shared.stop()
    }

    /// Notifies the playback session that the app is about to terminate.
    public static func appWillTerminate() {
        AudioPlaybackService.shared.appWillTerminate()
    }

    /// Hands the player the app's lookup for the on-device copy of a node, so a track the user
    /// has already downloaded plays from that file instead of being streamed back
    public static func registerLocalFileURLProvider(
        _ provider: @escaping @Sendable (any PlayableNode) -> URL?
    ) {
        DependencyInjection.localFileURLProvider = provider
    }
}
