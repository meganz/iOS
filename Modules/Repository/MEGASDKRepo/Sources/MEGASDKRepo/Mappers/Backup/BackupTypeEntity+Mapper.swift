import MEGADomain
import MEGASdk

extension MEGABackupType {
    public func toBackupTypeEntity() -> BackupTypeEntity {
        switch self {
        case .invalid: return .invalid
        case .twoWay: return .twoWay
        case .upSync: return .upSync
        case .downSync: return .downSync
        case .cameraUpload: return .cameraUpload
        case .mediaUpload: return .mediaUpload
        case .backupUpload: return .backupUpload
        @unknown default: return .invalid
        }
    }
}

extension BackupTypeEntity {
    public func toMEGABackupType() -> MEGABackupType {
        switch self {
        case .invalid: return .invalid
        case .twoWay: return .twoWay
        case .upSync: return .upSync
        case .downSync: return .downSync
        case .cameraUpload: return .cameraUpload
        case .mediaUpload: return .mediaUpload
        case .backupUpload: return .backupUpload
        }
    }
}
