import MEGADomain
import MEGASdk

extension CollisionResolutionEntity {
    func toCollisionResolution() -> CollisionResolution {
        switch self {
        case .overwrite: .overwrite
        case .renameNewWithSuffix: .newWithN
        case .renameOldWithSuffix: .existingToOldN
        @unknown default: .newWithN
        }
    }
}
