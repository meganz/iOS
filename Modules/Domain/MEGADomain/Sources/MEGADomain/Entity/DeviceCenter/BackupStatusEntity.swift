import Foundation

public enum BackupStatusEntity: Hashable, Sendable {
    case inactive
    case upToDate
    case offline
    case blocked
    case outOfQuota
    case error
    case disabled
    case paused
    case updating
    case scanning
    case initialising
    case backupStopped
    case noCameraUploads
}
