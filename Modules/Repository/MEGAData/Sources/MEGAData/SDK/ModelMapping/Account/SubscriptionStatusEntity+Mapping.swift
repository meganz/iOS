import MEGADomain
import MEGASdk

extension MEGASubscriptionStatus {
    func toSubscriptionStatusEntity() -> SubscriptionStatusEntity {
        switch self {
        case .none:
            return .none
        case .valid:
            return .valid
        case .invalid:
            return .invalid
        @unknown default:
            return .none
        }
    }
}
