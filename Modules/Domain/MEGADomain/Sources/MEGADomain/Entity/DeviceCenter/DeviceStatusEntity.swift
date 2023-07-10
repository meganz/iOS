import Foundation

public enum DeviceStatusEntity: Hashable, Sendable {
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
