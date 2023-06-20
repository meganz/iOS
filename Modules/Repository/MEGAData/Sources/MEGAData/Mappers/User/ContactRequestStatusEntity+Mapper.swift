import MEGADomain
import MEGASdk

extension MEGAContactRequestStatus {
    
    public func toContactRequestStatus() -> ContactRequestStatusEntity {
        switch self {
        case .unresolved: return .unresolved
        case .accepted: return .accepted
        case .denied: return .denied
        case .ignored: return .ignored
        case .deleted: return .deleted
        case .reminded: return .reminded
        @unknown default: return .unresolved
        }
    }
    
}
