import Foundation
import MEGALogger

final class MEGALogPlaybackReporter: PlaybackReporting, @unchecked Sendable {
    /// We want to ensure that the reporting is not done in the main thread,
    /// so we use a utility queue to handle the reporting operations.
    private let queue = DispatchQueue(
        label: "nz.mega.PlaybackReporting",
        qos: .utility
    )

    private var playerName = "now set"

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private var formattedTimestamp: String {
        dateFormatter.string(from: Date())
    }

    func playbackPlayerOption(_ option: VideoPlayerOption) {
        playerName = option.rawValue
        queue.async {
            MEGALogInfo(self.logMessage("Playback player option set to \(option.rawValue)"))
        }
    }

    func playbackStateDidChange(_ state: PlaybackState) {
        queue.async {
            MEGALogInfo(self.logMessage("Playback state changed to \(state)"))
        }
    }

    func playbackCurrentTimeDidChange(_ currentTime: Duration) {
        queue.async {
            MEGALogDebug(self.logMessage("Playback current time changed to \(currentTime)"))
        }
    }

    func playbackRequested() {
        queue.async {
            MEGALogInfo(self.logMessage("Playback requested"))
        }
    }

    func playbackStarted() {
        queue.async {
            MEGALogInfo(self.logMessage("Playback started"))
        }
    }

    func playbackStallStarted() {
        queue.async {
            MEGALogWarning(self.logMessage("Playback stall started"))
        }
    }

    func playbackStallEnded() {
        queue.async {
            MEGALogWarning(self.logMessage("Playback stall ended"))
        }
    }

    func playbackDebugMessage(_ message: String) {
        queue.async {
            MEGALogDebug(self.logMessage(message))
        }
    }

    private func logMessage(_ message: String) -> String {
        "[\(formattedTimestamp)] [\(playerName)] \(message)"
    }
}
