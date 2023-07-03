import Foundation

public enum BackupTypeEntity: Sendable {
    case invalid
    case twoWay
    case upSync
    case downSync
    case cameraUpload
    case mediaUpload
    case backupUpload
}
