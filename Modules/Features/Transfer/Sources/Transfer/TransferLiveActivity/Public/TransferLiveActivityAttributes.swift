import ActivityKit
import Foundation

@available(iOS 16.2, *)
public struct TransferLiveActivityAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable, Sendable {
        public let progressFraction: Double
        public let state: TransferLiveActivityState
        public let direction: TransferLiveActivityDirection?

        // Pre-formatted display strings produced on the app side so the widget
        // process is a pure renderer (no localization or formatting in-widget).
        public let statusText: String
        public let percentageText: String
        public let fileCountText: String
        public let formattedSpeed: String

        public init(
            progressFraction: Double,
            state: TransferLiveActivityState,
            direction: TransferLiveActivityDirection?,
            statusText: String,
            percentageText: String,
            fileCountText: String,
            formattedSpeed: String
        ) {
            self.progressFraction = progressFraction
            self.state = state
            self.direction = direction
            self.statusText = statusText
            self.percentageText = percentageText
            self.fileCountText = fileCountText
            self.formattedSpeed = formattedSpeed
        }
    }

    public init() {}
}

/// IPC payload type encoded inside `TransferLiveActivityAttributes.ContentState`
/// and decoded by the widget extension process. The `String` raw value is
/// intentional: it pins the Codable wire format to stable identifiers
/// (e.g. `"paused"`) which are easier to inspect when debugging the cross-process
/// payload, and decouples the on-the-wire key from the Swift case name so the
/// case can be renamed in code without changing the encoded format.
/// Not a Domain entity, so the no-raw-value rule for Domain enums does not apply.
public enum TransferLiveActivityState: String, Codable, Hashable, Sendable {
    case active
    case paused
    case error
    case overquota
    case completed
}

/// IPC payload type. See `TransferLiveActivityState` for the rationale behind
/// the `String` raw value.
public enum TransferLiveActivityDirection: String, Codable, Hashable, Sendable {
    case uploading
    case downloading
    case mixed
}
