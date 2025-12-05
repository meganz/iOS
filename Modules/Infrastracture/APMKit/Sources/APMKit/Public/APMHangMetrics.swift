import Foundation

public struct APMHangMetrics: Equatable, Sendable {
    public let threshold: TimeInterval
    public var hangDuration: TimeInterval = 0.0
    public var capturedStack = [UInt64]()
    public var runloopActivity: CFRunLoopActivity?
    public var deviceLocale: String?
}
