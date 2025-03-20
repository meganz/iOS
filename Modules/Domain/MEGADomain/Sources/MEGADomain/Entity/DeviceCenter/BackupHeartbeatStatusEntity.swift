import Foundation

public enum BackupHeartbeatStatusEntity: Sendable {
    case upToDate
    case syncing
    case pending
    case inactive
    case stalled
    case unknown
}
