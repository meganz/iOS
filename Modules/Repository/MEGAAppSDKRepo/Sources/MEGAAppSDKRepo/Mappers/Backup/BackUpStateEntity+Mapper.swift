import MEGADomain
import MEGASdk

extension BackUpState {
    public func toBackUpStateEntity() -> BackUpStateEntity {
        switch self {
        case .invalid: return .invalid
        case .notInitialized: return .notInitialized
        case .active: return .active
        case .failed: return .failed
        case .temporaryDisabled: return .temporaryDisabled
        case .disabled: return .disabled
        case .pauseUp: return .pauseUp
        case .pauseDown: return .pauseDown
        case .pauseFull: return .pauseFull
        case .deleted: return .deleted
        case .unknown: return .unknown
        @unknown default: return .unknown
        }
    }
}

extension BackUpStateEntity {
    public func toBackUpState() -> BackUpState {
        switch self {
        case .invalid: return .invalid
        case .notInitialized: return .notInitialized
        case .active: return .active
        case .failed: return .failed
        case .temporaryDisabled: return .temporaryDisabled
        case .disabled: return .disabled
        case .pauseUp: return .pauseUp
        case .pauseDown: return .pauseDown
        case .pauseFull: return .pauseFull
        case .deleted: return .deleted
        case .unknown: return .unknown
        }
    }
}
