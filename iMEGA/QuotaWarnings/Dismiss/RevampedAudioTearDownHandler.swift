import MEGAAudioPlayer
import QuotaWarnings

/// Stops any ongoing audio playback, which closes the player screen with it.
///
/// Drives the revamped player. The screen is not dismissed from here: the player's view model observes the
/// playback session and dismisses itself once the session ends, so ending the session is the whole teardown.
struct RevampedAudioTearDownHandler: QuotaDialogDismissHandling {
    private let endSession: @MainActor () -> Void

    init(endSession: @escaping @MainActor () -> Void = MEGAAudioPlayerSession.stop) {
        self.endSession = endSession
    }

    func handleDismiss() async {
        endSession()
    }
}
