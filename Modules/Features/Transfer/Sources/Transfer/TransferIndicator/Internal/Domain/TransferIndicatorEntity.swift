import CoreGraphics

enum TransferIndicatorEntity: Sendable, Equatable {
    case hidden
    case inProgress(progress: CGFloat)
    case paused(progress: CGFloat)
    case completed
    case warning
    case error
}
