public enum TransferStateEntity: Int, Sendable {
    case none
    case queued
    case active
    case paused
    case retrying
    case completing
    case complete
    case cancelled
    case failed
}
