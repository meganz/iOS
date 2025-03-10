import MEGASdk

extension Retry {
    public func toWaitingReasonEntity() -> WaitingReasonEntity {
        switch self {
        case .none: .none
        case .connectivity: .connectivity
        case .serversBusy: .serverBusy
        case .apiLock: .apiLock
        case .rateLimit: .rateLimit
        case .unknown: .unknown
        @unknown default: .unknown
        }
    }
}
