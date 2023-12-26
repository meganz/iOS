import MEGADomain
import MEGASdk

extension MEGASetType {
    public func toSetTypeEntity() -> SetTypeEntity {
        switch self {
        case .invalid:
            return .invalid
        case .album:
            return .album
        case .playlist:
            return .playlist
        @unknown default:
            return .invalid
        }
    }
}
