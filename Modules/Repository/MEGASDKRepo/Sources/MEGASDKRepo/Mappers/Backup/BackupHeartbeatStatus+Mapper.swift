import MEGADomain
import MEGASdk

extension MEGABackupHeartbeatStatus {
    public func toBackupHeartbeatStatusEntity() -> BackupHeartbeatStatusEntity {
        switch self {
        case .upToDate: return .upToDate
        case .syncing: return .syncing
        case .pending: return .pending
        case .inactive: return .inactive
        case .unknown: return .unknown
        @unknown default: return .unknown
        }
    }
}

extension BackupHeartbeatStatusEntity {
    public func toMEGABackupHeartbeatStatus() -> MEGABackupHeartbeatStatus {
        switch self {
        case .upToDate: return .upToDate
        case .syncing: return .syncing
        case .pending: return .pending
        case .inactive: return .inactive
        case .unknown: return .unknown
        }
    }
}
