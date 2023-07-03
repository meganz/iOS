import Foundation

public enum SyncStateEntity: Sendable {
    case notInitialized
    case upToDate
    case syncing
    case pending
    case inactive
    case unknown
}
