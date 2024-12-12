import MEGADomain
import MEGASdk

extension Retry {
    public func toWaitingReasonEntity() -> WaitingReasonEntity {
        switch self {
        case .none: .none
        case .connectivity: .connectivity
        case .serversBusy: .serverBusy
        case .apiLock: .apiLock
        case .rateLimit: .rateLimit
        case .localLock: .localLock
        case .unknown: .unknown
        @unknown default: .unknown
        }
    }
}

extension WaitingReasonEntity {
    public func toRetry() -> Retry {
        switch self {
        case .none: .none
        case .connectivity: .connectivity
        case .serverBusy: .serversBusy
        case .apiLock: .apiLock
        case .rateLimit: .rateLimit
        case .localLock: .localLock
        case .unknown: .unknown
        }
    }
}
