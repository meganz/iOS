import MEGADomain
import MEGASdk

extension MEGABackupHeartbeatStatus {
    public func toBackupHeartbeatStatusEntity() -> BackupHeartbeatStatusEntity {
        return switch self {
        case .upToDate: .upToDate
        case .syncing: .syncing
        case .pending: .pending
        case .inactive: .inactive
        case .stalled: .stalled
        case .unknown: .unknown
        @unknown default: .unknown
        }
    }
}

extension BackupHeartbeatStatusEntity {
    public func toMEGABackupHeartbeatStatus() -> MEGABackupHeartbeatStatus {
        return switch self {
        case .upToDate: .upToDate
        case .syncing: .syncing
        case .pending: .pending
        case .inactive: .inactive
        case .stalled: .stalled
        case .unknown: .unknown
        }
    }
}
