import UIKit

/// A player screen a Picture in Picture session can run on.
@MainActor
protocol PictureInPictureHost: AnyObject {
    func endPictureInPictureSession()
}

/// The one Picture in Picture session the player can have at a time
@MainActor
enum VideoPlayerPictureInPictureSession {
    private static var host: (any PictureInPictureHost)?

    static func isHosted(by host: some PictureInPictureHost) -> Bool {
        self.host === host
    }

    /// Takes over the session, ending whatever was running before.
    static func begin(hostedBy host: some PictureInPictureHost) {
        endRunningSession()
        self.host = host
    }

    /// Gives up the session without tearing anything down, for a host whose window has already gone on
    /// its own — the user closed it, or restored it to full screen
    static func relinquish(by host: some PictureInPictureHost) {
        guard self.host === host else { return }

        self.host = nil
    }

    /// Ends the running session, if any
    static func endRunningSession() {
        guard let host else { return }

        self.host = nil
        host.endPictureInPictureSession()
    }
}
