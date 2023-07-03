import MEGADomain
import MEGASdk

extension MEGASyncState {
    public func toSyncStateEntity() -> SyncStateEntity {
        switch self {
        case .notInitialized: return .notInitialized
        case .upToDate: return .upToDate
        case .syncing: return .syncing
        case .pending: return .pending
        case .inactive: return .inactive
        case .unknown: return .unknown
        @unknown default: return .unknown
        }
    }
}
