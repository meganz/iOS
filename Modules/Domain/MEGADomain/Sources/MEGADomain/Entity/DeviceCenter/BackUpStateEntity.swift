import Foundation

public enum BackUpStateEntity: Sendable {
    case invalid
    case notInitialized
    case active
    case failed
    case temporaryDisabled
    case disabled
    case pauseUp
    case pauseDown
    case pauseFull
    case deleted
    case unknown
    
    public var isPaused: Bool {
        self == .pauseUp || self == .pauseDown || self == .pauseFull
    }
}
