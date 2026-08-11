import Foundation

/// Why a playback session never produced a first frame.
enum StartupFailureReason: Equatable {
    /// The player item or the player itself reported an error before the first frame arrived.
    case playbackError(message: String?)

    /// Playback was torn down while still loading and nothing had reported an error.
    case noFirstFrame(elapsedMilliseconds: Int32)

    /// `0` for no error, `1` for a playback error.
    var errCode: Int32 {
        switch self {
        case .playbackError: 1
        case .noFirstFrame: 0
        }
    }

    /// The free-form half of the event, only meaningful when read against ``errCode``.
    var reason: String {
        switch self {
        case .playbackError(let message):
            Self.sanitized(message) ?? Self.unknownError
        case .noFirstFrame(let elapsedMilliseconds):
            // A bare millisecond count, so the dashboard can aggregate it as a number.
            String(elapsedMilliseconds)
        }
    }

    /// The player's error text is free-form and was written for the debug log, so it is trimmed
    /// and capped before it travels with an event.
    private static func sanitized(_ message: String?) -> String? {
        guard let trimmed = message?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxReasonLength))
    }

    private static let maxReasonLength = 200
    private static let unknownError = "Unknown error"
}
