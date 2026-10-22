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

    /// Drops any interruption another player left behind, so the next session starts clean. Only for
    /// when no other player can still be running, or is about to be ended too, such as on logout: one that
    /// stays open would lose its lock screen / Control Center commands.
    public static func resetInterruption() {
        AudioPlaybackService.shared.resetInterruption()
    }

    /// Steps the session back while another player, such as a video, takes over: pauses playback
    /// and hands the lock screen / Control Center commands over to that player. Each call must be
    /// balanced by one `endInterruption(shouldResume:)`, so players whose lifetimes overlap can each make their own.
    public static func beginInterruption() {
        AudioPlaybackService.shared.beginInterruption()
    }

    /// Takes the lock screen / Control Center back once the last other player is done, resuming playback
    /// when `shouldResume` is set and the session was playing as the interruption began.
    public static func endInterruption(shouldResume: Bool) {
        AudioPlaybackService.shared.endInterruption(shouldResume: shouldResume)
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

    /// Hands the player the app's `leftOffItemRecordUseCase`, so a stopped track is added
    /// to or dropped from the LeftOffItem store.
    public static func registerLeftOffItemRecordUseCase(_ useCase: some LeftOffItemRecordUseCaseProtocol) {
        DependencyInjection.leftOffItemRecordUseCase = useCase
    }
}
