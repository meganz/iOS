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

extension MEGAShareType {
    public func toNodeAccessTypeEntity() -> NodeAccessTypeEntity {
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
        guard size > 0 else {
            return []
        }
        
        return (0..<size).compactMap {
            share(at: $0)?.toShareEntity()
        }
    }
}
