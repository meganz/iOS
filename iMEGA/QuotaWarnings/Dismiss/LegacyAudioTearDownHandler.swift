import QuotaWarnings

/// Stops any ongoing audio playback and dismisses the player screen.
///
/// Drives the pre-revamp player. `AudioTearDownHandlerFactory` picks between this and
/// `RevampedAudioTearDownHandler`.
struct LegacyAudioTearDownHandler: QuotaDialogDismissHandling {
    private let audioPlayerHandler: any AudioPlayerHandlerProtocol

    init(audioPlayerHandler: any AudioPlayerHandlerProtocol = AudioPlayerManager.shared) {
        self.audioPlayerHandler = audioPlayerHandler
    }

    func handleDismiss() async {
        // The dismissal needs no guard of its own: it is already scoped to the presented screen.
        await audioPlayerHandler.dismissFullScreenPlayer()

        // Deliberately `isPlayerDefined()` rather than `isPlayerAlive()`. The latter is
        // `(isPlaying || isPaused) && !isCloseRequested`, so it reads false for a player that is merely loading,
        // stalled, or already closing
        guard audioPlayerHandler.isPlayerDefined() else { return }

        audioPlayerHandler.closePlayer()
    }
}
