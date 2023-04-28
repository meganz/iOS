import MEGADomain
import MEGASdk

extension MEGAShareType {
    public func toShareAccessLevelEntity() -> ShareAccessLevelEntity {
        switch self {
        case .accessUnknown:
            return .unknown
        case .accessRead:
            return .read
        case .accessReadWrite:
            return .readWrite
        case .accessFull:
            return .full
        case .accessOwner:
            return .owner
        @unknown default:
            return .unknown
        }
    }
}

extension MEGAShare {
    public func toShareEntity() -> ShareEntity {
        ShareEntity(sharedUserEmail: user,
                    nodeHandle: nodeHandle,
                    accessLevel: access.toShareAccessLevelEntity(),
                    createdDate: timestamp,
                    isPending: isPending,
                    isVerified: isVerified)
    }
}

extension MEGAShareList {
    public func toShareEntities() -> [ShareEntity] {
        guard let count = size?.intValue else {
            return []
        }
        
        guard count > 0 else {
            return []
        }
        
        return (0..<count).compactMap {
            share(at: $0)?.toShareEntity()
        }
    }
}
